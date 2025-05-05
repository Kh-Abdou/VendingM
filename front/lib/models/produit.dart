class Produit {
  final String id;
  final String nom;
  final double prix;
  final String image;
  final bool disponible;

  Produit({
    required this.id,
    required this.nom,
    required this.prix,
    required this.image,
    required this.disponible,
  });

  factory Produit.fromJson(Map<String, dynamic> json) {
    return Produit(
      id: json['_id'] ?? '',
      // Le backend utilise 'name' au lieu de 'nom'
      nom: json['name'] ?? '',
      // Le backend utilise 'price' au lieu de 'prix'
      prix: double.parse((json['price'] ?? 0).toString()),
      // Le champ 'image' reste le même
      image: json['image'] ?? '',
      // Le backend utilise 'isActive' au lieu de 'disponible'
      disponible: json['isActive'] ?? true,
    );
  }
}

class ProduitPanier {
  final Produit produit;
  int quantite;

  ProduitPanier({
    required this.produit,
    required this.quantite,
  });
}
