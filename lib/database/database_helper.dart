import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:assetguard/models/job.dart';
import 'package:assetguard/models/inspection_item.dart';

/// DatabaseHelper singleton class that manages SQLite database operations
class DatabaseHelper {
  DatabaseHelper._privateConstructor();

  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  static const String _dbName = 'assetguard.db';
  static const int _dbVersion = 1;

  // Table names
  static const String tableJobs = 'jobs';
  static const String tableInspectionItems = 'inspection_items';
  static const String tableAttachments = 'attachments';

  // Job table columns
  static const String jobIdColumn = 'job_id';
  static const String siteNameColumn = 'site_name';
  static const String assignedEngineerColumn = 'assigned_engineer';
  static const String dueDateColumn = 'due_date';
  static const String statusColumn = 'status';

  // InspectionItem table columns
  static const String inspectionIdColumn = 'inspection_id';
  static const String inspectionJobIdColumn = 'job_id';
  static const String notesColumn = 'notes';
  static const String resultColumn = 'result';
  static const String updatedAtColumn = 'updated_at';
  static const String syncStateColumn = 'sync_state';

  /// initialize database
Future<Database> get database async {
  if (_database != null) {
    return _database!;
  }

  _database = await _initDatabase();
  return _database!;
}

Future<Database> _initDatabase() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final dbPath = await databaseFactory.getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _dbVersion,
        onCreate: _onCreate,
      ),
    );
  } else {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }
}

  /// create database tables
  Future<void> _onCreate(Database db, int version) async {
    // create jobs table
    await db.execute('''
      CREATE TABLE $tableJobs (
        $jobIdColumn TEXT PRIMARY KEY,
        $siteNameColumn TEXT NOT NULL,
        $assignedEngineerColumn TEXT NOT NULL,
        $dueDateColumn TEXT NOT NULL,
        $statusColumn TEXT NOT NULL
      )
    ''');

    // create inspection_items table
    await db.execute('''
      CREATE TABLE $tableInspectionItems (
        inspection_id TEXT PRIMARY KEY,
        job_id TEXT NOT NULL,
        notes TEXT,
        result TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_state TEXT NOT NULL,
        FOREIGN KEY (job_id) REFERENCES $tableJobs($jobIdColumn)
      )
    ''');

    // create attachments table
    await db.execute('''
      CREATE TABLE $tableAttachments (
        attachment_id TEXT PRIMARY KEY,
        inspection_id TEXT NOT NULL,
        file_path TEXT NOT NULL,
        file_type TEXT NOT NULL,
        sync_state TEXT NOT NULL,
        FOREIGN KEY (inspection_id) REFERENCES $tableInspectionItems(inspection_id)
      )
    ''');
  }

  // ========== JOBS CRUD OPERATIONS ==========

  /// insert a new job into the database
  /// returns the number of rows affected
  Future<int> insertJob(Job job) async {
    Database db = await database;
    return await db.insert(
      tableJobs,
      job.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// fetch all jobs from the database
  Future<List<Job>> getAllJobs() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableJobs);

    if (maps.isEmpty) {
      return [];
    }

    return List.generate(maps.length, (i) {
      return Job.fromMap(maps[i]);
    });
  }

  /// fetch a single job by its job_id
  Future<Job?> getJobById(String jobId) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableJobs,
      where: '$jobIdColumn = ?',
      whereArgs: [jobId],
    );

    if (maps.isEmpty) {
      return null;
    }

    return Job.fromMap(maps[0]);
  }

  /// update an existing job in the database
  Future<int> updateJob(Job job) async {
    Database db = await database;
    return await db.update(
      tableJobs,
      job.toMap(),
      where: '$jobIdColumn = ?',
      whereArgs: [job.jobId],
    );
  }

  /// delete a job from the database by its job_id
  Future<int> deleteJob(String jobId) async {
    Database db = await database;
    return await db.delete(
      tableJobs,
      where: '$jobIdColumn = ?',
      whereArgs: [jobId],
    );
  }

  /// get jobs filtered by status
  Future<List<Job>> getJobsByStatus(String status) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableJobs,
      where: '$statusColumn = ?',
      whereArgs: [status],
    );

    if (maps.isEmpty) {
      return [];
    }

    return List.generate(maps.length, (i) {
      return Job.fromMap(maps[i]);
    });
  }

  /// seed the database with sample jobs for testing
  /// only inserts if no jobs exist
  Future<void> seedSampleJobs() async {
    final existingJobs = await getAllJobs();

    if (existingJobs.isNotEmpty) {
      return;
    }

    final sampleJobs = [
      Job(
        jobId: 'JOB001',
        siteName: 'Telecom Mast Inspection',
        assignedEngineer: 'Demo Engineer',
        dueDate: DateTime.now().add(const Duration(days: 2)),
        status: 'Assigned',
      ),
      Job(
        jobId: 'JOB002',
        siteName: 'Substation Safety Check',
        assignedEngineer: 'Demo Engineer',
        dueDate: DateTime.now().add(const Duration(days: 5)),
        status: 'Assigned',
      ),
      Job(
        jobId: 'JOB003',
        siteName: 'Pipeline Valve Inspection',
        assignedEngineer: 'Demo Engineer',
        dueDate: DateTime.now().add(const Duration(days: 7)),
        status: 'Assigned',
      ),
    ];

    for (final job in sampleJobs) {
      await insertJob(job);
    }
  }

  // ========== INSPECTION ITEMS CRUD OPERATIONS ==========

  /// insert a new inspection item into the database
  Future<int> insertInspectionItem(InspectionItem item) async {
    Database db = await database;
    return await db.insert(
      tableInspectionItems,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// fetch all inspection items for a specific job
  Future<List<InspectionItem>> getInspectionItemsByJobId(String jobId) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableInspectionItems,
      where: '$inspectionJobIdColumn = ?',
      whereArgs: [jobId],
    );

    if (maps.isEmpty) {
      return [];
    }

    return List.generate(maps.length, (i) {
      return InspectionItem.fromMap(maps[i]);
    });
  }

  /// fetch a single inspection item by its inspection_id
  Future<InspectionItem?> getInspectionItemById(String inspectionId) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableInspectionItems,
      where: '$inspectionIdColumn = ?',
      whereArgs: [inspectionId],
    );

    if (maps.isEmpty) {
      return null;
    }

    return InspectionItem.fromMap(maps[0]);
  }

  /// update an existing inspection item
  Future<int> updateInspectionItem(InspectionItem item) async {
    Database db = await database;
    return await db.update(
      tableInspectionItems,
      item.toMap(),
      where: '$inspectionIdColumn = ?',
      whereArgs: [item.inspectionId],
    );
  }

  /// delete an inspection item by its inspection_id
  Future<int> deleteInspectionItem(String inspectionId) async {
    Database db = await database;
    return await db.delete(
      tableInspectionItems,
      where: '$inspectionIdColumn = ?',
      whereArgs: [inspectionId],
    );
  }
  // TODO: Implement attachments methods

  /// Close the database connection
  Future<void> closeDatabase() async {
    Database db = await database;
    await db.close();
  }
}
