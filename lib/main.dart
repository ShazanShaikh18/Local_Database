import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = openDatabase(
    join(await getDatabasesPath(), 'my_database.db'),
    onCreate: (db, version) {
      return db.execute(
        'CREATE TABLE my_table(id INTEGER PRIMARY KEY, name TEXT, age INTEGER)',
      );
    },
    version: 1,
  );

  runApp(MyApp(database));
}

class MyApp extends StatelessWidget {
  final Future<Database> database;

  const MyApp(this.database, {super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SQFlite Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(database),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final Future<Database> database;

  const MyHomePage(this.database, {super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController nameController = TextEditingController();
  TextEditingController ageController = TextEditingController();

  Future<void> insertData() async {
    final db = await widget.database;

    await db.insert(
      'my_table',
      {
        'name': nameController.text,
        'age': int.parse(ageController.text),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Clear text fields after inserting data ]
    nameController.clear();
    ageController.clear();

    setState(() {});
  }

  Future<List<Map<String, dynamic>>> getData() async {
    final db = await widget.database;

    return await db.query('my_table');
  }

  Future<void> updateData(int id) async {
    final db = await widget.database;

    await db.update(
      'my_table',
      {
        'name': nameController.text,
        'age': int.parse(ageController.text),
      },
      where: 'id = ?',
      whereArgs: [id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    setState(() {});
  }

  Future<void> deleteData(int id) async {
    final db = await widget.database;

    await db.delete(
      'my_table',
      where: 'id = ?',
      whereArgs: [id],
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        centerTitle: true,
        title: const Text('SQFlite Example', style: TextStyle(color: Colors.white),),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              TextField(
                controller: nameController,
                decoration: const InputDecoration(hintText: 'Enter Name:'),
              ),

              TextField(
                controller: ageController,
                decoration: const InputDecoration(hintText: 'Enter Age:'),
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 40,),

              ElevatedButton(
                style: ButtonStyle(backgroundColor: MaterialStatePropertyAll(Colors.teal.shade100)),
                onPressed: insertData,
                child: const Text('Insert Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
              ),

              const SizedBox(height: 40,),

              FutureBuilder<List<Map<String, dynamic>>>(
                future: getData(),
                builder: (context, snapshot) {

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('No data available.');
                  } else{
                    return Expanded(
                        child: ListView.builder(
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            final data = snapshot.data![index];
                            return ListTile(
                              title: Column(
                                children: [
                                  Text(data['name'] ?? ''),
                                ],
                              ),
                              leading: Text(data['age'].toString() ?? '', style: const TextStyle(fontSize: 16),),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      nameController.text = data['name'] ?? '';
                                      ageController.text =
                                          data['age'].toString() ?? '';
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text(
                                            'Update Data',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w500),
                                          ),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              TextField(
                                                controller: nameController,
                                                decoration: const InputDecoration(
                                                    hintText: 'Enter Name'),
                                              ),
                                              TextField(
                                                controller: ageController,
                                                decoration: const InputDecoration(
                                                    hintText: 'Enter Age'),
                                                keyboardType:
                                                TextInputType.number,
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            ElevatedButton(
                                              onPressed: () {
                                                updateData(data['id']);
                                                Navigator.pop(context);
                                              },
                                              style: ButtonStyle(
                                                backgroundColor:
                                                MaterialStateProperty.all(
                                                    Colors.teal.shade200),
                                              ),
                                              child: const Text('Update',
                                                  style: TextStyle(
                                                      color: Colors.white)),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              style: ButtonStyle(
                                                backgroundColor:
                                                MaterialStateProperty.all(
                                                    Colors.red.shade300),
                                              ),
                                              child: const Text('Cancel',
                                                  style: TextStyle(
                                                      color: Colors.white)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),

                                  IconButton(
                                    icon: const Icon(CupertinoIcons.delete_solid),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete Data', style: TextStyle(fontWeight: FontWeight.w500),),
                                          content: const Text('Are you sure you want to delete this data?'),
                                          actions: [
                                            ElevatedButton(
                                              onPressed: () {
                                                deleteData(snapshot.data![index]['id']);
                                                Navigator.pop(context);
                                              },
                                              style: ButtonStyle(backgroundColor: MaterialStatePropertyAll(Colors.teal.shade200)),
                                              child: const Text('Delete', style: TextStyle(color: Colors.white),),

                                            ),

                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              style: ButtonStyle(backgroundColor: MaterialStatePropertyAll(Colors.red.shade300)),
                                              child: const Text('Cancel', style: TextStyle(color: Colors.white),),
                                            ),
                                          ],
                                        ),);
                                    },),
                                ],
                              ),
                            );
                          },));}
                },)
            ],
          ),
        ),
      ),
    );
  }
}
