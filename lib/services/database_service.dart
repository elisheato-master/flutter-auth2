import 'package:mongo_dart/mongo_dart.dart';
import '../models/user_model.dart';
import '../config/constants.dart';

class DatabaseService {
  Db? _db;
  
  Future<Db> get database async {
    if (_db != null) return _db!;
    
    // Connect to MongoDB
    _db = await Db.create(Constants.mongoDbUri);
    await _db!.open();
    
    return _db!;
  }
  
  // Create a new user
  Future<void> createUser(UserModel user, String hashedPassword) async {
    final db = await database;
    final userCollection = db.collection(Constants.usersCollection);
    
    // Check if user already exists
    final existingUser = await userCollection.findOne({'email': user.email});
    
    if (existingUser != null) {
      throw Exception('User already exists');
    }
    
    // Create user document
    final userData = user.toMap();
    userData['password'] = hashedPassword;
    
    await userCollection.insertOne(userData);
  }
  
  // Create or update a user (for OAuth)
  Future<void> createOrUpdateUser(UserModel user) async {
    final db = await database;
    final userCollection = db.collection(Constants.usersCollection);
    
    // Check if user already exists
    final existingUser = await userCollection.findOne({'email': user.email});
    
    if (existingUser != null) {
      // Update existing user
      await userCollection.updateOne(
        where.eq('email', user.email),
        modify.set('id', user.id)
              .set('displayName', user.displayName)
              .set('photoUrl', user.photoUrl)
              .set('authType', user.authType.toString()),
      );
    } else {
      // Create new user
      await userCollection.insertOne(user.toMap());
    }
  }
  
  // Get user by email
  Future<UserModel?> getUserByEmail(String email) async {
    final db = await database;
    final userCollection = db.collection(Constants.usersCollection);
    
    final userData = await userCollection.findOne({'email': email});
    
    if (userData != null) {
      return UserModel.fromMap(userData);
    }
    
    return null;
  }
  
  // Verify password
  Future<bool> verifyPassword(String email, String hashedPassword) async {
    final db = await database;
    final userCollection = db.collection(Constants.usersCollection);
    
    final userData = await userCollection.findOne({
      'email': email,
      'password': hashedPassword,
    });
    
    return userData != null;
  }
  
  // Close database connection
  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
    }
  }
}
