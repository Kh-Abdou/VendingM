import 'package:flutter/material.dart';

class MachineStatusPage extends StatefulWidget {
  final Color primaryColor;
  final Color buttonColor;
  final Color buttonTextColor;

  const MachineStatusPage({
    super.key,
    required this.primaryColor,
    required this.buttonColor,
    required this.buttonTextColor,
  });

  @override
  _MachineStatusPageState createState() => _MachineStatusPageState();
}

class _MachineStatusPageState extends State<MachineStatusPage> {
  bool _isRefreshing = false;

  // Données simulées du distributeur
  final Map<String, dynamic> _machine = {
    'id': 1,
    'location': 'Université - Bloc A',
    'status': 'Opérationnel',
    'lastMaintenance': '2023-11-20',
  };

  // Liste des statuts de distributeur possibles
  final List<String> _machineStatuses = [
    'Opérationnel',
    'En maintenance',
    'En panne',
    'Hors service',
    'Nécessite réapprovisionnement'
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: widget.primaryColor.withOpacity(0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'État du distributeur',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isRefreshing ? null : _refreshMachineStatus,
                icon: _isRefreshing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh, color: Colors.white),
                label: Text(
                  _isRefreshing ? 'Actualisation...' : 'Actualiser',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.buttonColor,
                  foregroundColor: widget.buttonTextColor,
                  disabledBackgroundColor: widget.buttonColor.withOpacity(0.6),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Machine status card
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            getMachineStatusIcon(_machine['status']),
                            const SizedBox(width: 10),
                            Text(
                              _machine['status'],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color:
                                    getMachineStatusColor(_machine['status']),
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        ListTile(
                          title: const Text('Emplacement'),
                          subtitle: Text(_machine['location']),
                          leading: const Icon(Icons.location_on),
                        ),
                        ListTile(
                          title: const Text('Dernière maintenance'),
                          subtitle: Text(_machine['lastMaintenance']),
                          leading: const Icon(Icons.calendar_today),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.edit, color: Colors.white),
                            label: const Text(
                              'Mettre à jour le statut',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              _showEditMachineStatusDialog(_machine);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.buttonColor,
                              foregroundColor: widget.buttonTextColor,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 15,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Recent activities section
                const Text(
                  'Activités récentes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: ListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: const [
                      ListTile(
                        leading: Icon(Icons.build, color: Colors.blue),
                        title: Text('Maintenance effectuée'),
                        subtitle: Text('20/11/2023 - Remplacement des filtres'),
                      ),
                      Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.warning, color: Colors.amber),
                        title: Text('Problème technique résolu'),
                        subtitle: Text(
                            '15/11/2023 - Calibrage du système de paiement'),
                      ),
                      Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.inventory_2, color: Colors.green),
                        title: Text('Réapprovisionnement'),
                        subtitle: Text('10/11/2023 - Stock complété'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Add a refresh function for the machine status
  void _refreshMachineStatus() {
    setState(() {
      _isRefreshing = true;
    });

    // Simulate a network request with a delay
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        // Update with "new" data
        _machine['lastMaintenance'] =
            DateTime.now().toString().substring(0, 10);

        // Randomly change the status to simulate real updates
        final random = DateTime.now().millisecond % 3;
        if (random == 0 && _machine['status'] != 'Opérationnel') {
          _machine['status'] = 'Opérationnel';
          _machine.remove('issue');
        } else if (random == 1 && _machine['status'] != 'En maintenance') {
          _machine['status'] = 'En maintenance';
          _machine['issue'] = 'Maintenance programmée';
        }

        _isRefreshing = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Données actualisées avec succès'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    });
  }

  Color getMachineStatusColor(String status) {
    switch (status) {
      case 'Opérationnel':
        return Colors.green;
      case 'En maintenance':
        return Colors.blue;
      case 'En panne':
        return Colors.red;
      case 'Hors service':
        return Colors.grey;
      case 'Nécessite réapprovisionnement':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  Widget getMachineStatusIcon(String status) {
    IconData iconData;
    Color iconColor = getMachineStatusColor(status);

    switch (status) {
      case 'Opérationnel':
        iconData = Icons.check_circle;
        break;
      case 'En maintenance':
        iconData = Icons.build_circle;
        break;
      case 'En panne':
        iconData = Icons.error;
        break;
      case 'Hors service':
        iconData = Icons.cancel;
        break;
      case 'Nécessite réapprovisionnement':
        iconData = Icons.inventory;
        break;
      default:
        iconData = Icons.help;
    }

    return Icon(iconData, color: iconColor, size: 30);
  }

  void _showEditMachineStatusDialog(Map<String, dynamic> machine) {
    String currentStatus = machine['status'];
    String? issue = machine['issue'];
    final issueController = TextEditingController(text: issue);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Mettre à jour le statut du distributeur'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('État actuel:'),
                  DropdownButton<String>(
                    value: currentStatus,
                    isExpanded: true,
                    items: _machineStatuses.map((String status) {
                      return DropdownMenuItem<String>(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          currentStatus = newValue;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Description du problème (si applicable):'),
                  TextField(
                    controller: issueController,
                    decoration: const InputDecoration(
                      hintText: 'Décrivez le problème...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      machine['status'] = currentStatus;

                      // Ajouter ou supprimer le champ 'issue' en fonction de l'état
                      if (currentStatus == 'Opérationnel') {
                        machine.remove('issue');
                      } else if (issueController.text.isNotEmpty) {
                        machine['issue'] = issueController.text;
                      }
                    });

                    Navigator.pop(context);
                    // Hide any existing SnackBar before showing a new one
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('État du distributeur mis à jour avec succès'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.buttonColor,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Mettre à jour',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
