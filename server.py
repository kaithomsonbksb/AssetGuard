"""
AssetGuard Inspection Sync Server
Flask API for syncing inspection data from mobile clients
"""

from flask import Flask, request, jsonify, render_template_string
from flask_cors import CORS
import sqlite3
from datetime import datetime
import os

app = Flask(__name__)
CORS(app)

# Database configuration
DB_FILE = "inspections.db"

def get_db():
    """Get database connection"""
    conn = sqlite3.connect(DB_FILE, check_same_thread=False)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    """Initialize database tables"""
    conn = get_db()
    cursor = conn.cursor()
    
    # Create jobs table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS jobs (
            job_id TEXT PRIMARY KEY,
            site_name TEXT NOT NULL,
            assigned_engineer TEXT NOT NULL,
            due_date TEXT NOT NULL,
            status TEXT NOT NULL,
            created_at TEXT NOT NULL
        )
    """)
    
    # Create inspections table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS inspections (
            inspection_id TEXT PRIMARY KEY,
            job_id TEXT NOT NULL,
            notes TEXT NOT NULL,
            result TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            sync_state TEXT DEFAULT 'synced',
            created_at TEXT NOT NULL,
            FOREIGN KEY (job_id) REFERENCES jobs(job_id)
        )
    """)
    
    # Create sync logs for audit trail
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS sync_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            inspection_id TEXT NOT NULL,
            status TEXT NOT NULL,
            error_message TEXT,
            timestamp TEXT NOT NULL,
            FOREIGN KEY (inspection_id) REFERENCES inspections(inspection_id)
        )
    """)
    
    conn.commit()
    conn.close()

# Initialize database on startup
init_db()

# ==================== API ENDPOINTS ====================

@app.route("/health", methods=["GET"])
def health():
    """Health check endpoint"""
    return jsonify({"status": "ok", "service": "AssetGuard Inspection Sync"}), 200


@app.route("/inspections/sync", methods=["POST"])
def sync_inspection():
    """
    Sync a single inspection item from mobile client
    Expected JSON: {
        "inspection_id": "uuid",
        "job_id": "job-id",
        "notes": "inspection notes",
        "result": "Pass|Fail|Requires attention",
        "updated_at": "ISO8601 timestamp"
    }
    """
    try:
        data = request.json
        if not data:
            return jsonify({"error": "No JSON data provided"}), 400
        
        # Validate required fields
        required_fields = ["inspection_id", "job_id", "notes", "result", "updated_at"]
        if not all(field in data for field in required_fields):
            return jsonify({"error": "Missing required fields"}), 400
        
        inspection_id = data.get("inspection_id")
        job_id = data.get("job_id")
        notes = data.get("notes")
        result = data.get("result")
        updated_at = data.get("updated_at")
        
        # Validate result value
        valid_results = ["Pass", "Fail", "Requires attention"]
        if result not in valid_results:
            return jsonify({"error": f"Invalid result. Must be one of: {valid_results}"}), 400
        
        conn = get_db()
        cursor = conn.cursor()
        
        # Check if inspection exists
        cursor.execute("SELECT 1 FROM inspections WHERE inspection_id = ?", (inspection_id,))
        exists = cursor.fetchone()
        
        try:
            if exists:
                # Update existing inspection
                cursor.execute("""
                    UPDATE inspections 
                    SET job_id=?, notes=?, result=?, updated_at=?, sync_state='synced'
                    WHERE inspection_id=?
                """, (job_id, notes, result, updated_at, inspection_id))
            else:
                # Insert new inspection
                cursor.execute("""
                    INSERT INTO inspections 
                    (inspection_id, job_id, notes, result, updated_at, sync_state, created_at)
                    VALUES (?, ?, ?, ?, ?, 'synced', ?)
                """, (inspection_id, job_id, notes, result, updated_at, datetime.utcnow().isoformat()))
            
            conn.commit()
            
            # Log successful sync
            cursor.execute("""
                INSERT INTO sync_logs (inspection_id, status, timestamp)
                VALUES (?, 'success', ?)
            """, (inspection_id, datetime.utcnow().isoformat()))
            conn.commit()
            
            return jsonify({
                "message": "Inspection synced successfully",
                "inspection_id": inspection_id,
                "sync_state": "synced"
            }), 200
            
        except Exception as db_error:
            conn.rollback()
            
            # Log failed sync
            cursor.execute("""
                INSERT INTO sync_logs (inspection_id, status, error_message, timestamp)
                VALUES (?, 'error', ?, ?)
            """, (inspection_id, str(db_error), datetime.utcnow().isoformat()))
            conn.commit()
            
            return jsonify({"error": f"Database error: {str(db_error)}"}), 500
        
        finally:
            conn.close()
    
    except Exception as e:
        return jsonify({"error": f"Server error: {str(e)}"}), 500


@app.route("/inspections/sync-batch", methods=["POST"])
def sync_batch():
    """
    Sync multiple inspection items in one request (batch sync)
    Expected JSON: {
        "inspections": [
            { "inspection_id": "...", "job_id": "...", ... },
            { ... }
        ]
    }
    """
    try:
        data = request.json
        if not data or "inspections" not in data:
            return jsonify({"error": "No inspections data provided"}), 400
        
        inspections = data.get("inspections", [])
        if not isinstance(inspections, list):
            return jsonify({"error": "Inspections must be a list"}), 400
        
        results = {
            "successful": [],
            "failed": []
        }
        
        for inspection in inspections:
            try:
                required_fields = ["inspection_id", "job_id", "notes", "result", "updated_at"]
                if not all(field in inspection for field in required_fields):
                    results["failed"].append({
                        "inspection_id": inspection.get("inspection_id", "unknown"),
                        "error": "Missing required fields"
                    })
                    continue
                
                result = inspection.get("result")
                valid_results = ["Pass", "Fail", "Requires attention"]
                if result not in valid_results:
                    results["failed"].append({
                        "inspection_id": inspection.get("inspection_id"),
                        "error": f"Invalid result: {result}"
                    })
                    continue
                
                conn = get_db()
                cursor = conn.cursor()
                
                inspection_id = inspection.get("inspection_id")
                
                cursor.execute("SELECT 1 FROM inspections WHERE inspection_id = ?", (inspection_id,))
                exists = cursor.fetchone()
                
                if exists:
                    cursor.execute("""
                        UPDATE inspections 
                        SET job_id=?, notes=?, result=?, updated_at=?, sync_state='synced'
                        WHERE inspection_id=?
                    """, (inspection.get("job_id"), inspection.get("notes"), 
                          inspection.get("result"), inspection.get("updated_at"), inspection_id))
                else:
                    cursor.execute("""
                        INSERT INTO inspections 
                        (inspection_id, job_id, notes, result, updated_at, sync_state, created_at)
                        VALUES (?, ?, ?, ?, ?, 'synced', ?)
                    """, (inspection_id, inspection.get("job_id"), inspection.get("notes"),
                          inspection.get("result"), inspection.get("updated_at"), 
                          datetime.utcnow().isoformat()))
                
                conn.commit()
                
                # Log successful sync
                cursor.execute("""
                    INSERT INTO sync_logs (inspection_id, status, timestamp)
                    VALUES (?, 'success', ?)
                """, (inspection_id, datetime.utcnow().isoformat()))
                conn.commit()
                conn.close()
                
                results["successful"].append({"inspection_id": inspection_id})
                
            except Exception as e:
                results["failed"].append({
                    "inspection_id": inspection.get("inspection_id", "unknown"),
                    "error": str(e)
                })
        
        return jsonify({
            "message": "Batch sync completed",
            "results": results,
            "successful_count": len(results["successful"]),
            "failed_count": len(results["failed"])
        }), 200
    
    except Exception as e:
        return jsonify({"error": f"Server error: {str(e)}"}), 500


@app.route("/inspections/<inspection_id>", methods=["GET"])
def get_inspection(inspection_id):
    """Get a specific inspection by ID"""
    try:
        conn = get_db()
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT inspection_id, job_id, notes, result, updated_at, sync_state, created_at
            FROM inspections
            WHERE inspection_id = ?
        """, (inspection_id,))
        
        row = cursor.fetchone()
        conn.close()
        
        if not row:
            return jsonify({"error": "Inspection not found"}), 404
        
        return jsonify({
            "inspection_id": row["inspection_id"],
            "job_id": row["job_id"],
            "notes": row["notes"],
            "result": row["result"],
            "updated_at": row["updated_at"],
            "sync_state": row["sync_state"],
            "created_at": row["created_at"]
        }), 200
    
    except Exception as e:
        return jsonify({"error": f"Server error: {str(e)}"}), 500


@app.route("/inspections", methods=["GET"])
def list_inspections():
    """List all inspections with optional filtering"""
    try:
        job_id = request.args.get("job_id")
        result = request.args.get("result")
        sync_state = request.args.get("sync_state")
        
        conn = get_db()
        cursor = conn.cursor()
        
        query = "SELECT inspection_id, job_id, notes, result, updated_at, sync_state, created_at FROM inspections WHERE 1=1"
        params = []
        
        if job_id:
            query += " AND job_id = ?"
            params.append(job_id)
        
        if result:
            query += " AND result = ?"
            params.append(result)
        
        if sync_state:
            query += " AND sync_state = ?"
            params.append(sync_state)
        
        query += " ORDER BY created_at DESC LIMIT 100"
        
        cursor.execute(query, params)
        rows = cursor.fetchall()
        conn.close()
        
        inspections = [{
            "inspection_id": row["inspection_id"],
            "job_id": row["job_id"],
            "notes": row["notes"],
            "result": row["result"],
            "updated_at": row["updated_at"],
            "sync_state": row["sync_state"],
            "created_at": row["created_at"]
        } for row in rows]
        
        return jsonify({
            "count": len(inspections),
            "inspections": inspections
        }), 200
    
    except Exception as e:
        return jsonify({"error": f"Server error: {str(e)}"}), 500


@app.route("/sync-logs", methods=["GET"])
def get_sync_logs():
    """Get recent sync logs for monitoring"""
    try:
        limit = request.args.get("limit", default=50, type=int)
        
        conn = get_db()
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT id, inspection_id, status, error_message, timestamp
            FROM sync_logs
            ORDER BY timestamp DESC
            LIMIT ?
        """, (limit,))
        
        rows = cursor.fetchall()
        conn.close()
        
        logs = [{
            "id": row["id"],
            "inspection_id": row["inspection_id"],
            "status": row["status"],
            "error_message": row["error_message"],
            "timestamp": row["timestamp"]
        } for row in rows]
        
        return jsonify({
            "count": len(logs),
            "logs": logs
        }), 200
    
    except Exception as e:
        return jsonify({"error": f"Server error: {str(e)}"}), 500


@app.route("/stats", methods=["GET"])
def get_stats():
    """Get sync statistics"""
    try:
        conn = get_db()
        cursor = conn.cursor()
        
        # Total inspections
        cursor.execute("SELECT COUNT(*) as count FROM inspections")
        total = cursor.fetchone()["count"]
        
        # Synced inspections
        cursor.execute("SELECT COUNT(*) as count FROM inspections WHERE sync_state='synced'")
        synced = cursor.fetchone()["count"]
        
        # Failed inspections
        cursor.execute("SELECT COUNT(*) as count FROM inspections WHERE sync_state='failed'")
        failed = cursor.fetchone()["count"]
        
        # Pending inspections
        cursor.execute("SELECT COUNT(*) as count FROM inspections WHERE sync_state='pending'")
        pending = cursor.fetchone()["count"]
        
        # Results distribution
        cursor.execute("""
            SELECT result, COUNT(*) as count 
            FROM inspections 
            GROUP BY result
        """)
        results_dist = {row["result"]: row["count"] for row in cursor.fetchall()}
        
        conn.close()
        
        return jsonify({
            "total_inspections": total,
            "synced": synced,
            "failed": failed,
            "pending": pending,
            "results_distribution": results_dist
        }), 200
    
    except Exception as e:
        return jsonify({"error": f"Server error: {str(e)}"}), 500


@app.route("/", methods=["GET"])
def dashboard():
    """Admin dashboard for monitoring"""
    try:
        conn = get_db()
        cursor = conn.cursor()
        
        # Get statistics
        cursor.execute("SELECT COUNT(*) as count FROM inspections")
        total = cursor.fetchone()["count"]
        
        cursor.execute("SELECT COUNT(*) as count FROM inspections WHERE sync_state='synced'")
        synced = cursor.fetchone()["count"]
        
        cursor.execute("SELECT COUNT(*) as count FROM inspections WHERE sync_state='failed'")
        failed = cursor.fetchone()["count"]
        
        cursor.execute("SELECT COUNT(*) as count FROM inspections WHERE sync_state='pending'")
        pending = cursor.fetchone()["count"]
        
        # Recent inspections
        cursor.execute("""
            SELECT inspection_id, job_id, result, sync_state, created_at
            FROM inspections
            ORDER BY created_at DESC
            LIMIT 10
        """)
        recent = cursor.fetchall()
        
        conn.close()
        
        html = f"""
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>AssetGuard Sync Server Dashboard</title>
            <style>
                * {{ margin: 0; padding: 0; box-sizing: border-box; }}
                body {{
                    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    min-height: 100vh;
                    padding: 20px;
                }}
                .container {{
                    max-width: 1200px;
                    margin: 0 auto;
                }}
                .header {{
                    background: white;
                    padding: 30px;
                    border-radius: 10px;
                    margin-bottom: 20px;
                    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
                }}
                h1 {{
                    color: #333;
                    margin-bottom: 10px;
                }}
                .status {{
                    color: #27ae60;
                    font-weight: bold;
                    font-size: 14px;
                }}
                .stats {{
                    display: grid;
                    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
                    gap: 20px;
                    margin-bottom: 20px;
                }}
                .stat-card {{
                    background: white;
                    padding: 20px;
                    border-radius: 10px;
                    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
                    text-align: center;
                }}
                .stat-value {{
                    font-size: 32px;
                    font-weight: bold;
                    color: #667eea;
                    margin: 10px 0;
                }}
                .stat-label {{
                    color: #666;
                    font-size: 14px;
                }}
                .stat-card.synced .stat-value {{ color: #27ae60; }}
                .stat-card.failed .stat-value {{ color: #e74c3c; }}
                .stat-card.pending .stat-value {{ color: #f39c12; }}
                .table-container {{
                    background: white;
                    border-radius: 10px;
                    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
                    overflow: hidden;
                }}
                table {{
                    width: 100%;
                    border-collapse: collapse;
                }}
                th {{
                    background: #667eea;
                    color: white;
                    padding: 15px;
                    text-align: left;
                    font-weight: 500;
                }}
                td {{
                    padding: 12px 15px;
                    border-bottom: 1px solid #eee;
                }}
                tr:hover {{ background: #f8f9fa; }}
                .badge {{
                    display: inline-block;
                    padding: 4px 8px;
                    border-radius: 4px;
                    font-size: 12px;
                    font-weight: 500;
                }}
                .badge.synced {{ background: #d4edda; color: #155724; }}
                .badge.failed {{ background: #f8d7da; color: #721c24; }}
                .badge.pending {{ background: #fff3cd; color: #856404; }}
                .badge.pass {{ background: #d4edda; color: #155724; }}
                .badge.fail {{ background: #f8d7da; color: #721c24; }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>📊 AssetGuard Inspection Sync Server</h1>
                    <div class="status">● Server is online</div>
                </div>
                
                <div class="stats">
                    <div class="stat-card">
                        <div class="stat-label">Total Inspections</div>
                        <div class="stat-value">{total}</div>
                    </div>
                    <div class="stat-card synced">
                        <div class="stat-label">✓ Synced</div>
                        <div class="stat-value">{synced}</div>
                    </div>
                    <div class="stat-card failed">
                        <div class="stat-label">✗ Failed</div>
                        <div class="stat-value">{failed}</div>
                    </div>
                    <div class="stat-card pending">
                        <div class="stat-label">⧗ Pending</div>
                        <div class="stat-value">{pending}</div>
                    </div>
                </div>
                
                <div class="table-container">
                    <table>
                        <thead>
                            <tr>
                                <th>Inspection ID</th>
                                <th>Job ID</th>
                                <th>Result</th>
                                <th>Sync State</th>
                                <th>Created At</th>
                            </tr>
                        </thead>
                        <tbody>
        """
        
        for row in recent:
            html += f"""
                            <tr>
                                <td><code>{row['inspection_id'][:8]}...</code></td>
                                <td>{row['job_id']}</td>
                                <td><span class="badge {row['result'].lower()}">{row['result']}</span></td>
                                <td><span class="badge {row['sync_state']}">{row['sync_state'].upper()}</span></td>
                                <td>{row['created_at'][:10]}</td>
                            </tr>
            """
        
        html += """
                        </tbody>
                    </table>
                </div>
            </div>
        </body>
        </html>
        """
        
        return render_template_string(html)
    
    except Exception as e:
        return jsonify({"error": f"Server error: {str(e)}"}), 500


if __name__ == "__main__":
    # Run on local network
    app.run(host="0.0.0.0", port=5000, debug=True)
