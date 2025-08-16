import 'package:flutter/material.dart';
import 'products_page.dart';

class CategoriesPage extends StatelessWidget {
  final String category; // Men, Women, Kids

  const CategoriesPage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    // Subcategories with products
    final Map<String, List<Map<String, dynamic>>> subcategories = {
      "Men": [
        {
          "name": "Jodhpuri",
          "products": [
            {
              "name": "Classic Jodhpuri",
              "price": "₹2500",
              "description": "Elegant Classic Jodhpuri suit perfect for weddings.",
              "images": [
                "assets/images/categories/jodhpuri.webp",
                "assets/images/categories/blue jodhpuri.webp",
                "assets/images/categories/jodhpuri.webp"
              ]
            },
            {
              "name": "Blue Jodhpuri",
              "price": "₹2800",
              "description": "Royal Blue Jodhpuri with modern design.",
              "images": [
                "assets/images/categories/blue jodhpuri.webp",
                "assets/images/categories/jodhpuri.webp",
                "assets/images/categories/blue jodhpuri.webp"
              ]
            },
          ]
        },
        {
          "name": "Suit",
          "products": [
            {
              "name": "Formal Suit",
              "price": "₹3000",
              "description": "Classic formal suit for office or events.",
              "images": [
                "assets/images/categories/suit.webp",
                "assets/images/categories/slim fit suit.webp",
                "assets/images/categories/suit.webp"
              ]
            },
            {
              "name": "Slim Fit Suit",
              "price": "₹3500",
              "description": "Stylish slim fit suit for modern look.",
              "images": [
                "assets/images/categories/slim fit suit.webp",
                "assets/images/categories/suit.webp",
                "assets/images/categories/slim fit suit.webp"
              ]
            },
          ]
        },
        {
          "name": "Navratri Kurta",
          "products": [
            {
              "name": "Designer Kurta",
              "price": "₹1500",
              "description": "Designer Kurta for Navratri special occasions.",
              "images": [
                "assets/images/categories/navratrikurta.webp",
                "assets/images/categories/white navratri kurta.webp",
                "assets/images/categories/navratrikurta.webp"
              ]
            },
            {
              "name": "White Kurta",
              "price": "₹1800",
              "description": "Elegant white Kurta for festive events.",
              "images": [
                "assets/images/categories/white navratri kurta.webp",
                "assets/images/categories/navratrikurta.webp",
                "assets/images/categories/white navratri kurta.webp"
              ]
            },
          ]
        },
      ],
      "Women": [
        {
          "name": "Saree",
          "products": [
            {
              "name": "Sari",
              "price": "₹2000",
              "description": "Elegant silk Sari for weddings.",
              "images": [
                "assets/images/categories/sari.webp",
                "assets/images/categories/cotton sari.webp",
                "assets/images/categories/sari.webp"
              ]
            },
            {
              "name": "Cotton Sari",
              "price": "₹1200",
              "description": "Comfortable cotton Sari for daily wear.",
              "images": [
                "assets/images/categories/cotton sari.webp",
                "assets/images/categories/sari.webp",
                "assets/images/categories/cotton sari.webp"
              ]
            },
          ]
        },
        {
          "name": "Green Navratri Choli",
          "products": [
            {
              "name": "Green Navratri Choli",
              "price": "₹2500",
              "description": "Beautiful green choli for Navratri festival.",
              "images": [
                "assets/images/categories/green navratri choli.webp",
                "assets/images/categories/green navratri choli.webp",
                "assets/images/categories/green navratri choli.webp"
              ]
            },
            {
              "name": "pink Navratri Choli",
              "price": "₹1200",
              "description": "Comfortable pink choli for daily wear.",
              "images": [
                "assets/images/categories/pinkcholi 1.jpeg",
                "assets/images/categories/pinkcholi 2.jpeg",
                "assets/images/categories/pinkcholi 3.jpeg"
              ]
            },
          ]
        },
      ],
      "Kids": [
        {
          "name": "Kids Casual",
          "products": [
            {
              "name": "Kids Casual",
              "price": "₹800",
              "description": "Comfortable casual wear for kids.",
              "images": [
                "assets/images/categories/kids casual.webp",
                "assets/images/categories/kids casual.webp",
                "assets/images/categories/kids casual.webp"
              ]
            }
          ]
        },
        {
          "name": "Kids Festival",
          "products": [
            {
              "name": "Kids Festival",
              "price": "₹1000",
              "description": "Colorful festival wear for kids.",
              "images": [
                "assets/images/categories/kids festival.webp",
                "assets/images/categories/kids festival.webp",
                "assets/images/categories/kids festival.webp"
              ]
            }
          ]
        },
        {
          "name": "Kids Party",
          "products": [
            {
              "name": "Kids Party",
              "price": "₹1200",
              "description": "Cute party dress for kids.",
              "images": [
                "assets/images/categories/kids party.webp",
                "assets/images/categories/kids party.webp",
                "assets/images/categories/kids party.webp"
              ]
            }
          ]
        },
      ],
    };

    final List<Map<String, dynamic>> items = subcategories[category] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text("$category Subcategories"),
        backgroundColor: Colors.purple.shade300,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemBuilder: (context, index) {
          final subcat = items[index];
          return GestureDetector(
            onTap: () {
              // Open ProductsPage for that subcategory
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductsPage(
                    subcategory: subcat["name"],
                    products: List<Map<String, dynamic>>.from(subcat["products"]),
                  ),
                ),
              );
            },
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.asset(
                        subcat["products"][0]["images"][0], // first product image as thumbnail
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      subcat["name"],
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
