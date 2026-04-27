# AssetGuard Inspection Sync Server

A Flask-based REST API server for syncing inspection data from the AssetGuard mobile app.

## Features

- **Single Inspection Sync**: Upload individual inspections to the server
- **Batch Sync**: Efficiently sync multiple inspections in one request
- **Inspection Retrieval**: Query inspections by job ID, result, or sync state
- **Sync Logs**: Audit trail of all sync operations
- **Statistics**: Real-time stats on inspection data
- **Admin Dashboard**: Web-based monitoring interface

## Installation

### Prerequisites

- Python 3.7+
- pip (Python package manager)

### Setup

1. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

2. **Run the server**:
   ```bash
   python server.py
   ```

   The server will start on `http://localhost:5000` (or `http://192.168.1.91:5000` on your network)

## API Endpoints

### Health Check
```
GET /health
```
Check if the server is running.

**Response**:
```json
{
  "status": "ok",
  "service": "AssetGuard Inspection Sync"
}
```

---

### Sync Single Inspection
```
POST /inspections/sync
```
Upload a single inspection item.

**Request Body**:
```json
{
  "inspection_id": "uuid-string",
  "job_id": "JOB001",
  "notes": "Inspection findings and observations",
  "result": "Pass",
  "updated_at": "2024-04-27T10:30:00Z"
}
```

**Valid Result Values**: `Pass`, `Fail`, `Requires attention`

**Response**:
```json
{
  "message": "Inspection synced successfully",
  "inspection_id": "uuid-string",
  "sync_state": "synced"
}
```

**Status Codes**:
- `200`: Success
- `400`: Invalid request
- `500`: Server error

---

### Batch Sync Multiple Inspections
```
POST /inspections/sync-batch
```
Efficiently sync multiple inspections in one request.

**Request Body**:
```json
{
  "inspections": [
    {
      "inspection_id": "uuid-1",
      "job_id": "JOB001",
      "notes": "Notes 1",
      "result": "Pass",
      "updated_at": "2024-04-27T10:30:00Z"
    },
    {
      "inspection_id": "uuid-2",
      "job_id": "JOB002",
      "notes": "Notes 2",
      "result": "Fail",
      "updated_at": "2024-04-27T10:35:00Z"
    }
  ]
}
```

**Response**:
```json
{
  "message": "Batch sync completed",
  "results": {
    "successful": [
      {"inspection_id": "uuid-1"}
    ],
    "failed": [
      {"inspection_id": "uuid-2", "error": "Invalid result"}
    ]
  },
  "successful_count": 1,
  "failed_count": 1
}
```

---

### Get Inspection
```
GET /inspections/<inspection_id>
```
Retrieve a specific inspection by ID.

**Response**:
```json
{
  "inspection_id": "uuid-string",
  "job_id": "JOB001",
  "notes": "Inspection findings",
  "result": "Pass",
  "updated_at": "2024-04-27T10:30:00Z",
  "sync_state": "synced",
  "created_at": "2024-04-27T10:30:00Z"
}
```

---

### List Inspections
```
GET /inspections?job_id=JOB001&result=Pass&sync_state=synced
```
List inspections with optional filtering.

**Query Parameters**:
- `job_id` (optional): Filter by job ID
- `result` (optional): Filter by result (Pass, Fail, Requires attention)
- `sync_state` (optional): Filter by sync state (pending, synced, failed)

**Response**:
```json
{
  "count": 10,
  "inspections": [
    {
      "inspection_id": "uuid-1",
      "job_id": "JOB001",
      "notes": "Inspection findings",
      "result": "Pass",
      "updated_at": "2024-04-27T10:30:00Z",
      "sync_state": "synced",
      "created_at": "2024-04-27T10:30:00Z"
    }
  ]
}
```

---

### Get Sync Logs
```
GET /sync-logs?limit=50
```
Retrieve sync operation logs for audit/debugging.

**Query Parameters**:
- `limit` (optional): Max number of logs to return (default: 50)

**Response**:
```json
{
  "count": 50,
  "logs": [
    {
      "id": 1,
      "inspection_id": "uuid-1",
      "status": "success",
      "error_message": null,
      "timestamp": "2024-04-27T10:30:00Z"
    },
    {
      "id": 2,
      "inspection_id": "uuid-2",
      "status": "error",
      "error_message": "Invalid result value",
      "timestamp": "2024-04-27T10:31:00Z"
    }
  ]
}
```

---

### Get Statistics
```
GET /stats
```
Get sync statistics and inspection distribution.

**Response**:
```json
{
  "total_inspections": 100,
  "synced": 85,
  "failed": 10,
  "pending": 5,
  "results_distribution": {
    "Pass": 70,
    "Fail": 20,
    "Requires attention": 10
  }
}
```

---

### Admin Dashboard
```
GET /
```
Web-based monitoring dashboard showing real-time statistics and recent inspections.

Visit `http://192.168.1.91:5000/` in your browser.

## Mobile App Integration

### Configuring the Sync Manager

Update the `SyncManager` class in `lib/sync/sync_manager.dart`:

```dart
// Change this to your server URL
static const String _apiBaseUrl = 'http://192.168.1.91:5000';
```

### Using the Sync Manager

```dart
// Check server health
final isHealthy = await SyncManager.instance.checkServerHealth();

// Sync single inspection
await SyncManager.instance.syncPendingInspections();

// Batch sync (more efficient)
await SyncManager.instance.syncPendingInspectionsBatch();

// Retry failed inspections
await SyncManager.instance.retrySyncFailedInspections();
```

## Database Schema

### Inspections Table
```sql
CREATE TABLE inspections (
    inspection_id TEXT PRIMARY KEY,
    job_id TEXT NOT NULL,
    notes TEXT NOT NULL,
    result TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    sync_state TEXT DEFAULT 'synced',
    created_at TEXT NOT NULL,
    FOREIGN KEY (job_id) REFERENCES jobs(job_id)
)
```

### Jobs Table
```sql
CREATE TABLE jobs (
    job_id TEXT PRIMARY KEY,
    site_name TEXT NOT NULL,
    assigned_engineer TEXT NOT NULL,
    due_date TEXT NOT NULL,
    status TEXT NOT NULL,
    created_at TEXT NOT NULL
)
```

### Sync Logs Table
```sql
CREATE TABLE sync_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    inspection_id TEXT NOT NULL,
    status TEXT NOT NULL,
    error_message TEXT,
    timestamp TEXT NOT NULL,
    FOREIGN KEY (inspection_id) REFERENCES inspections(inspection_id)
)
```

## Error Handling

The server returns appropriate HTTP status codes:

| Status | Meaning |
|--------|---------|
| 200 | Success |
| 400 | Bad request (validation error) |
| 404 | Resource not found |
| 500 | Server error |

Example error response:
```json
{
  "error": "Invalid result. Must be one of: ['Pass', 'Fail', 'Requires attention']"
}
```

## Production Deployment

For production, consider:

1. **Use a production WSGI server**:
   ```bash
   pip install gunicorn
   gunicorn -w 4 -b 0.0.0.0:5000 server:app
   ```

2. **Enable HTTPS**: Use a reverse proxy like Nginx with SSL certificates

3. **Database**: Switch to PostgreSQL for better concurrency:
   ```bash
   pip install psycopg2-binary
   ```

4. **Environment Variables**: Store configuration in `.env`:
   ```
   FLASK_ENV=production
   DATABASE_URL=postgresql://...
   ```

5. **Logging**: Implement proper logging to files

6. **Monitoring**: Add health checks and alerts

## Troubleshooting

### Server won't start
- Check if port 5000 is already in use
- Ensure Python 3.7+ is installed
- Verify all dependencies are installed: `pip install -r requirements.txt`

### Mobile app can't connect
- Verify the server URL in `sync_manager.dart`
- Check firewall settings
- Ensure mobile device and server are on the same network
- Test with: `curl http://192.168.1.91:5000/health`

### Database locked error
- Close all other connections to the database
- Delete `inspections.db` to reset (warning: data loss)

## Support

For issues or questions, check the server logs:
```bash
# The Flask development server will print logs to console
# For production, configure logging to file
```
