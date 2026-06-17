import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../config/app_constants.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final String databasePath = await getDatabasesPath();
      final String path = join(databasePath, AppConstants.databaseName);

      return openDatabase(
        path,
        version: AppConstants.databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: (Database db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
      );
    } catch (_) {
      throw Exception('Unable to initialize the local database.');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.usersTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        profile_image_path TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.restaurantsTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        remote_id TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        address TEXT NOT NULL,
        place_type TEXT NOT NULL DEFAULT 'Restaurant',
        cuisine TEXT NOT NULL,
        phone TEXT NOT NULL,
        average_rating REAL NOT NULL DEFAULT 0,
        review_count INTEGER NOT NULL DEFAULT 0,
        is_cached INTEGER NOT NULL DEFAULT 1,
        is_user_created INTEGER NOT NULL DEFAULT 0,
        created_by INTEGER,
        description TEXT NOT NULL DEFAULT '',
        image_path TEXT NOT NULL DEFAULT '',
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.reviewsTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        restaurant_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        user_name TEXT NOT NULL,
        rating REAL NOT NULL,
        comment TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (restaurant_id) REFERENCES ${AppConstants.restaurantsTable}(id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES ${AppConstants.usersTable}(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.favoritesTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        restaurant_id INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES ${AppConstants.usersTable}(id) ON DELETE CASCADE,
        FOREIGN KEY (restaurant_id) REFERENCES ${AppConstants.restaurantsTable}(id) ON DELETE CASCADE,
        UNIQUE(user_id, restaurant_id)
      )
    ''');

    await _createIndexes(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      if (oldVersion < 2) {
        await db.execute('''
          ALTER TABLE ${AppConstants.restaurantsTable}
          ADD COLUMN is_user_created INTEGER NOT NULL DEFAULT 0
        ''');
        await db.execute('''
          ALTER TABLE ${AppConstants.restaurantsTable}
          ADD COLUMN created_by INTEGER
        ''');
        await db.execute('''
          ALTER TABLE ${AppConstants.restaurantsTable}
          ADD COLUMN description TEXT NOT NULL DEFAULT ''
        ''');
        await db.execute('''
          ALTER TABLE ${AppConstants.restaurantsTable}
          ADD COLUMN image_path TEXT NOT NULL DEFAULT ''
        ''');
      }

      if (oldVersion < 3) {
        await db.execute('''
          ALTER TABLE ${AppConstants.restaurantsTable}
          ADD COLUMN place_type TEXT NOT NULL DEFAULT 'Restaurant'
        ''');
      }

      if (oldVersion < 4) {
        await db.execute('''
          ALTER TABLE ${AppConstants.usersTable}
          ADD COLUMN profile_image_path TEXT NOT NULL DEFAULT ''
        ''');
      }

      await _createIndexes(db);
      await _normalizeUserData(db);
      await _normalizeRestaurantData(db);
    } catch (_) {
      throw Exception('Unable to upgrade the local database.');
    }
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_restaurants_remote_id
      ON ${AppConstants.restaurantsTable}(remote_id)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_restaurants_created_by
      ON ${AppConstants.restaurantsTable}(created_by)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_reviews_restaurant_id
      ON ${AppConstants.reviewsTable}(restaurant_id)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_favorites_user_id
      ON ${AppConstants.favoritesTable}(user_id)
    ''');
  }

  Future<void> _normalizeRestaurantData(Database db) async {
    await db.update(
      AppConstants.restaurantsTable,
      <String, Object>{
        'description': '',
      },
      where: 'description IS NULL',
    );

    await db.update(
      AppConstants.restaurantsTable,
      <String, Object>{
        'image_path': '',
      },
      where: 'image_path IS NULL',
    );

    await db.update(
      AppConstants.restaurantsTable,
      <String, Object>{
        'place_type': AppConstants.restaurantTypeRestaurant,
      },
      where: 'place_type IS NULL OR TRIM(place_type) = ?',
      whereArgs: <Object>[''],
    );
  }

  Future<void> _normalizeUserData(Database db) async {
    await db.update(
      AppConstants.usersTable,
      <String, Object>{
        'profile_image_path': '',
      },
      where: 'profile_image_path IS NULL',
    );
  }
}
