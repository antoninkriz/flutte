import 'package:flutte/utils/utils.dart';
import 'package:sqflite/sqflite.dart';

const _tableTx = 'tblTransactions';
const _txColumnId = 'id';
const _txColumnDate = 'dDate';
const _txColumnAmount = 'rAmount';
const _txColumnNote = 'sNote';
const _txColumnCategory = 'fkCategory';

const _tableCg = 'tblCategories';
const _cgColumnId = 'id';
const _cgColumnName = 'sName';
const _cgColumnParent = 'fkParent';

class DBProvider {
  DBProvider._();

  static final DBProvider db = DBProvider._();
  static Database _database;

  static List<Category> _categoriesChildrenList;
  static List<CategoryParent> _categoriesList;

  Future<List<CategoryParent>> get _categories async {
    if (_categoriesList != null) return _categoriesList;

    _categoriesList = await getCategories();
    return _categoriesList;
  }

  Future<List<Category>> get _categoriesChildren async {
    if (_categoriesChildrenList != null) return _categoriesChildrenList;

    final catList = List<Category>();
    final cats = await _categories;
    cats.forEach((CategoryParent cat) {
      catList.addAll(cat.children);
    });

    return _categoriesChildrenList = catList;
  }

  Future<Category> _category(int id) async =>
      id <= 0 ? null : (await _categoriesChildren).firstWhere((c) => c.id == id);

  Future<Database> get database async {
    if (_database != null) return _database;

    _database = await _initDB();
    return _database;
  }

  Future<Database> _initDB() async {
    var path = await getDatabasesPath();
    return await openDatabase('$path/transactions.db', version: 1, onOpen: (db) {},
        onCreate: (Database db, int version) async {
      await db.execute(""
          "CREATE TABLE IF NOT EXISTS $_tableCg ("
          "$_cgColumnId INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,"
          "$_cgColumnName TEXT NOT NULL DEFAULT '',"
          "$_cgColumnParent INTEGER DEFAULT NULL,"
          "FOREIGN KEY ($_cgColumnParent) REFERENCES $_tableCg($_cgColumnId));");
      await db.execute(""
          "CREATE TABLE IF NOT EXISTS $_tableTx ("
          "$_txColumnId INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,"
          "$_txColumnDate INT(4) NOT NULL DEFAULT (strftime('%s', 'now')),"
          "$_txColumnAmount DOUBLE NOT NULL DEFAULT 0.0,"
          "$_txColumnNote TEXT NOT NULL DEFAULT '',"
          "$_txColumnCategory INTEGER DEFAULT NULL);");
      await db.execute(""
          "INSERT INTO $_tableCg ($_cgColumnName) VALUES"
          "('food'), ('housing'), ('utilities'), ('personal'), ('education'), ('clothing'), ('transportation'), ('fun'), ('bills-giving'), ('health');");
      await db.execute(""
          "INSERT INTO $_tableCg ($_cgColumnParent, $_cgColumnName) VALUES"
          "(1, 'groceries'), (1, 'restaurants'), (1, 'pub'), (1, 'coffee'), (1, 'small'), (1, 'other'),"
          "(2, 'supplies'), (2, 'mortgage-rent'), (2, 'hoa'), (2, 'repairs'), (2, 'furniture-furnishings'), (2, 'other'),"
          "(3, 'electricity'), (3, 'water'), (3, 'gas'), (3, 'heating'), (3, 'garbage'), (3, 'phone'), (3, 'internet'), (3, 'tv'), (3, 'other'),"
          "(4, 'tobacco'), (4, 'gym'), (4, 'hair'), (4, 'cosmetics'), (4, 'subscriptions'), (4, 'other'),"
          "(5, 'books'), (5, 'supplies'), (5, 'conferences'), (5, 'other'),"
          "(6, 'shoes'), (6, 'clothes'), (6, 'underwear'), (6, 'accessories'), (6, 'other'),"
          "(7, 'parking'), (7, 'public'), (7, 'bus'), (7, 'train'), (7, 'plane'), (7, 'fuel'), (7, 'maintenance'), (7, 'other'),"
          "(8, 'entertainment'), (8, 'games'), (8, 'vacations'), (8, 'gifts'), (8, 'other'),"
          "(9, 'debts'), (9, 'taxes'), (9, 'loan'), (9, 'dontaions'), (9, 'other'),"
          "(10, 'insurance'), (10, 'dental'), (10, 'special'), (10, 'medications'), (10, 'investing'), (10, 'other');");
    });
  }

  Future<CategoryParent> getParentCategory(int id) async {
    final db = await database;

    final query = await db.query(_tableCg, columns: [_cgColumnId, _cgColumnName, _cgColumnParent]);

    final childMap = query.firstWhere((map) => map[_cgColumnId] == id);
    if (childMap == null) return null;

    final parentMap = query.firstWhere((map) => map[_cgColumnId] == childMap[_cgColumnParent]);
    if (parentMap == null) return null;

    final cat = CategoryParent.fromMap(parentMap);
    cat.children
        .addAll(query.where((mapChild) => mapChild[_cgColumnParent] == cat.id).map((map) => Category.fromMap(map)));

    return cat;
  }

  Future<List<CategoryParent>> getCategories() async {
    final db = await database;

    final query = await db.query(_tableCg, columns: [_cgColumnId, _cgColumnName, _cgColumnParent]);

    return query
        .where((map) => map[_cgColumnParent] == null)
        .map((mapParent) {
          final cat = CategoryParent.fromMap(mapParent);

          cat.children.addAll(query.where((mapChild) => mapChild[_cgColumnParent] == cat.id).map((map) {
            map = Map.from(map);
            map['$_cgColumnName parent'] = '$cat';
            return Category.fromMap(map);
          }));
          return cat;
        })
        .where((c) => c.children.length > 0)
        .toList();
  }

  Future<Transaction> insertTransaction(Transaction tx) async {
    final db = await database;
    print(tx.category.nameParent);
    print(tx.category);
    tx.id = await db.insert(_tableTx, tx.toMap());
    return tx;
  }

  Future<Transaction> getTransaction(int id) async {
    final db = await database;

    var maps = await db.query(
      _tableTx,
      columns: [_txColumnId, _txColumnDate, _txColumnAmount, _txColumnNote, _txColumnCategory],
      where: '$_txColumnId = ?',
      whereArgs: [id],
    );

    maps.forEach((m) async {
      var cat = await _category(m['$_txColumnCategory'] ?? -1);
      if (cat == null) cat = Category._(null, null, null);

      m = Map.from(m);

      m['$_txColumnCategory id'] = cat.id;
      m['$_txColumnCategory name'] = cat.name;
      m['$_txColumnCategory parent'] = cat.nameParent;
    });

    return maps.length != 0 ? Transaction.fromMap(maps.first) : null;
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;

    return await db.delete(
      _tableTx,
      where: '$_txColumnId = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateTransaction(Transaction tx) async {
    final db = await database;

    return await db.update(
      _tableTx,
      tx.toMap(),
      where: '$_txColumnId = ?',
      whereArgs: [tx.id],
    );
  }

  Future<List<Transaction>> getDay(DateTime date) async {
    final db = await database;

    final thisDay = Utils.time.getDateOnly(date);
    final nextDay = thisDay.add(Duration(days: 1));

    final res = await db.query(
      _tableTx,
      columns: [_txColumnId, _txColumnDate, _txColumnAmount, _txColumnNote, _txColumnCategory],
      where: '$_txColumnDate >= ? AND $_txColumnDate < ?',
      whereArgs: [thisDay.millisecondsSinceEpoch / 1000, nextDay.millisecondsSinceEpoch / 1000],
    );

    final transactions = List<Map<String, dynamic>>();

    for (var m in res) {
      var cat = await _category(m['$_txColumnCategory'] ?? -1);
      if (cat == null) cat = Category._(null, null, null);

      m = Map.from(m);

      m['$_txColumnCategory id'] = cat.id;
      m['$_txColumnCategory name'] = cat.name;
      m['$_txColumnCategory parent'] = cat.nameParent;

      transactions.add(m);
    }

    return transactions.map((m) => Transaction.fromMap(m)).toList();
  }

  Future<double> getSumDayTotal(DateTime date) async {
    final db = await database;

    final thisDay = Utils.time.getDateOnly(date);
    final nextDay = thisDay.add(Duration(days: 1));

    final thisMillis = thisDay.millisecondsSinceEpoch / 1000;
    final nextMillis = nextDay.millisecondsSinceEpoch / 1000;

    final res = await db.query(_tableTx,
        columns: [_txColumnAmount],
        where: '$_txColumnDate >= ? AND $_txColumnDate < ?',
        whereArgs: [thisMillis, nextMillis]);
    return res.fold(0.0, (prev, map) => prev + map[_txColumnAmount]) as double;
  }

  Future<double> getSumMonthTotal(DateTime date) async {
    final db = await database;

    final thisMonth = DateTime(date.year, date.month);
    final nextMonth = DateTime(date.year, date.month + 1);

    final thisMillis = thisMonth.millisecondsSinceEpoch / 1000;
    final nextMillis = nextMonth.millisecondsSinceEpoch / 1000;

    final res = await db.query(_tableTx,
        columns: [_txColumnAmount],
        where: '$_txColumnDate >= ? AND $_txColumnDate < ?',
        whereArgs: [thisMillis, nextMillis]);
    return res.fold(0.0, (prev, map) => prev + map[_txColumnAmount]) as double;
  }

  Future<double> getSumTotal() async {
    final db = await database;

    final res = await db.query(_tableTx, columns: [_txColumnAmount]);
    return res.fold(0.0, (prev, map) => prev + map[_txColumnAmount]) as double;
  }
}

class Category {
  int id;
  String name;
  String nameParent;

  @override
  String toString() => 'cat_$name';

  Category._(this.id, this.name, this.nameParent);

  Category.empty();

  factory Category.fromMap(Map<String, dynamic> map) => Category._(
        map[_cgColumnId] as int,
        map[_cgColumnName] as String,
        map['$_cgColumnName parent'] as String,
      );

  Map<String, dynamic> toMap() => {
        _cgColumnId: this.id,
        _cgColumnName: this.name,
      };
}

class CategoryParent {
  int id;
  String name;
  List<Category> children;

  @override
  String toString() => 'cat_parent_$name';

  CategoryParent._(this.id, this.name, this.children);

  CategoryParent.empty();

  factory CategoryParent.fromMap(Map<String, dynamic> map) => CategoryParent._(
        map[_cgColumnId] as int,
        map[_cgColumnName] as String,
        map['children'] as List<Category> ?? List<Category>(),
      );

  Map<String, dynamic> toMap() => {
        _cgColumnId: this.id,
        _cgColumnName: this.name,
        'children': this.children,
      };
}

class Transaction {
  int id;
  DateTime dateTime;
  double amount;
  String note;
  Category category;

  /// Public constructor to create a new transaction
  Transaction(this.amount, [this.note, this.dateTime, this.category]) {
    if (this.dateTime == null) this.dateTime = DateTime.now();

    if (this.note == null) this.note = '';
  }

  /// Private constructor to create an already existing transaction
  Transaction._(
    this.id,
    this.dateTime,
    this.amount,
    this.note,
    this.category,
  );

  Map<String, dynamic> toMap() => {
        _txColumnId: id,
        _txColumnDate: dateTime.millisecondsSinceEpoch / 1000,
        _txColumnAmount: amount,
        _txColumnNote: note,
        _txColumnCategory: category.id,
      };

  factory Transaction.fromMap(Map<String, dynamic> map) => Transaction._(
        map[_txColumnId],
        DateTime.fromMillisecondsSinceEpoch((map[_txColumnDate] * 1000.0).round()),
        map[_txColumnAmount],
        map[_txColumnNote],
        Category._(
          map['$_txColumnCategory id'],
          map['$_txColumnCategory name'],
          map['$_txColumnCategory parent'],
        ),
      );
}
