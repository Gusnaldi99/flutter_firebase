import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'biodata_service.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Instance untuk berkomunikasi dengan Firestore
  Biodataservice? service;

  // Variabel untuk menyimpan ID dokumen yang sedang dipilih (edit mode)
  String? selectedDocId;

  // Controller untuk input teks
  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final addressController = TextEditingController();

  @override
  void initState() {
    // Inisialisasi layanan Firestore
    service = Biodataservice(db: FirebaseFirestore.instance);
    super.initState();
  }

  // Fungsi untuk mengosongkan input field dan mereset selectedDocId
  void clearFields() {
    nameController.clear();
    ageController.clear();
    addressController.clear();
    setState(() {
      selectedDocId = null;
    });
  }

  // Fungsi untuk menyimpan data (tambah atau update)
  void saveData() {
    final name = nameController.text.trim();
    final age = ageController.text.trim();
    final address = addressController.text.trim();

    // Validasi agar tidak ada input yang kosong
    if (name.isEmpty || age.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    // Jika selectedDocId tidak null, berarti edit data
    if (selectedDocId != null) {
      service?.update(selectedDocId!, {
        'name': name,
        'age': age,
        'address': address,
      });
    } else {
      // Jika null, berarti tambah data baru
      service?.add({'name': name, 'age': age, 'address': address});
    }

    // Reset input setelah berhasil menyimpan
    clearFields();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Input Nama
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
              ),
              const SizedBox(height: 8),
              // Input Umur
              TextField(
                controller: ageController,
                decoration: InputDecoration(
                  labelText: 'Age',
                  prefixIcon: Icon(Icons.numbers),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              // Input Alamat
              TextField(
                controller: addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: StreamBuilder(
                  stream: service?.getBiodata(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting ||
                        snapshot.connectionState == ConnectionState.none) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Text("Error Fetching data: ${snapshot.error}");
                    } else if (snapshot.hasData &&
                        snapshot.data?.docs.isEmpty == true) {
                      return Text("No biodata found");
                    }

                    final documents = snapshot.data?.docs;
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: documents?.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(documents?[index]['name']),
                          subtitle: Text("Age: ${documents?[index]['age']}"),
                          onTap: () {
                            // Ketika data diklik, isi input field dengan data tersebut
                            nameController.text = documents?[index]['name'];
                            ageController.text = documents?[index]['age'];
                            addressController.text =
                                documents?[index]['address'];
                            setState(() {
                              selectedDocId = documents?[index].id;
                            });
                          },
                          trailing: IconButton(
                            onPressed: () {
                              // Hapus data saat tombol delete ditekan
                              if (documents?[index].id != null) {
                                service?.delete(documents![index].id);
                              }
                            },
                            icon: const Icon(Icons.delete),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: saveData,
      ),
    );
  }
}
