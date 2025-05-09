import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'dart:convert';

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
  bool _isConnectedToIoT = false;
  bool _isSimulatorOpen = false;
  Timer? _iotConnectionTimer;
  Timer? _simulatedEventTimer;

  // Liste des activités récentes (dynamique)
  List<Map<String, dynamic>> _recentActivities = [
    {
      'icon': Icons.build,
      'color': Colors.blue,
      'title': 'Maintenance effectuée',
      'subtitle': '20/11/2023 - Remplacement des filtres',
      'timestamp': DateTime(2023, 11, 20),
    },
    {
      'icon': Icons.warning,
      'color': Colors.amber,
      'title': 'Problème technique résolu',
      'subtitle': '15/11/2023 - Calibrage du système de paiement',
      'timestamp': DateTime(2023, 11, 15),
    },
    {
      'icon': Icons.inventory_2,
      'color': Colors.green,
      'title': 'Réapprovisionnement',
      'subtitle': '10/11/2023 - Stock complété',
      'timestamp': DateTime(2023, 11, 10),
    },
  ];

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
  void initState() {
    super.initState();
    // Démarrer la simulation de connexion IoT
    _startIoTSimulation();
  }

  @override
  void dispose() {
    // Arrêter les timers
    _iotConnectionTimer?.cancel();
    _simulatedEventTimer?.cancel();
    super.dispose();
  }

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
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _recentActivities.length,
                    itemBuilder: (context, index) {
                      final activity = _recentActivities[index];
                      return Column(
                        children: [
                          ListTile(
                            leading: Icon(activity['icon'] as IconData,
                                color: activity['color'] as Color),
                            title: Text(activity['title'] as String),
                            subtitle: Text(activity['subtitle'] as String),
                          ),
                          if (index < _recentActivities.length - 1)
                            const Divider(height: 1),
                        ],
                      );
                    },
                  ),
                ),

                // Simulateur IoT
                const SizedBox(height: 24),
                Card(
                  elevation: 3,
                  color: widget.primaryColor.withOpacity(0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: widget.primaryColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.developer_board,
                              color: widget.primaryColor,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Simulateur ESP32",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: widget.primaryColor,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _isConnectedToIoT
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.circle,
                                    size: 10,
                                    color: _isConnectedToIoT
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _isConnectedToIoT
                                        ? "Connecté"
                                        : "Déconnecté",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _isConnectedToIoT
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Simulation d'ouverture/fermeture du distributeur",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed:
                                    _isSimulatorOpen ? null : _simulateDoorOpen,
                                icon:
                                    const Icon(Icons.door_front_door_outlined),
                                label: const Text("Ouvrir la porte"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.grey,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: !_isSimulatorOpen
                                    ? null
                                    : _simulateDoorClose,
                                icon: const Icon(Icons.door_back_door_outlined),
                                label: const Text("Fermer la porte"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.grey,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _isSimulatorOpen
                                ? Colors.orange.withOpacity(0.1)
                                : Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _isSimulatorOpen
                                  ? Colors.orange.withOpacity(0.3)
                                  : Colors.green.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isSimulatorOpen
                                    ? Icons.warning
                                    : Icons.check_circle,
                                color: _isSimulatorOpen
                                    ? Colors.orange
                                    : Colors.green,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _isSimulatorOpen
                                      ? "Porte ouverte - Distributeur en maintenance"
                                      : "Porte fermée - Distributeur opérationnel",
                                  style: TextStyle(
                                    color: _isSimulatorOpen
                                        ? Colors.orange[800]
                                        : Colors.green[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Cette simulation remplace le capteur de porte réel que vous allez implémenter avec l'ESP32. Quand la porte est ouverte, le statut du distributeur change automatiquement.",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
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

  // Fonction pour démarrer la simulation IoT
  void _startIoTSimulation() {
    // Simuler une connexion au système IoT
    setState(() {
      _isConnectedToIoT = true;
    });

    // Démarrer un timer pour simuler des événements IoT aléatoires
    _simulatedEventTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      // Simuler des événements IoT aléatoires
      if (Random().nextDouble() < 0.3 && !_isSimulatorOpen) {
        _simulateRandomEvent();
      }
    });
  }

  // Fonction pour simuler un événement IoT aléatoire
  void _simulateRandomEvent() {
    final events = [
      {
        'title': 'Vérification système',
        'subtitle':
            '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} - Vérification automatique',
        'icon': Icons.check_circle_outline,
        'color': Colors.green,
      },
      {
        'title': 'Alerte de stock',
        'subtitle':
            '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} - Produit A presque épuisé',
        'icon': Icons.warning_amber_outlined,
        'color': Colors.amber,
      },
      {
        'title': 'Vente importante',
        'subtitle':
            '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} - Nombreuses transactions',
        'icon': Icons.trending_up,
        'color': Colors.blue,
      },
    ];

    final randomEvent = events[Random().nextInt(events.length)];
    _addActivity(
      randomEvent['title'] as String,
      randomEvent['subtitle'] as String,
      randomEvent['icon'] as IconData,
      randomEvent['color'] as Color,
    );
  }

  // Fonction pour ajouter une activité à l'historique
  void _addActivity(String title, String subtitle, IconData icon, Color color) {
    setState(() {
      _recentActivities.insert(0, {
        'icon': icon,
        'color': color,
        'title': title,
        'subtitle': subtitle,
        'timestamp': DateTime.now(),
      });

      // Limiter le nombre d'activités à 10
      if (_recentActivities.length > 10) {
        _recentActivities.removeLast();
      }
    });
  }

  // Fonction pour simuler l'ouverture du distributeur
  void _simulateDoorOpen() {
    setState(() {
      _isSimulatorOpen = true;

      // Changer l'état du distributeur en maintenance
      if (_machine['status'] != 'En maintenance') {
        String previousStatus = _machine['status'];
        _machine['status'] = 'En maintenance';
        _machine['issue'] = 'Porte ouverte - Accès de maintenance';

        // Ajouter cet événement aux activités récentes
        _addActivity(
          'Distributeur ouvert',
          '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} - Passage de $previousStatus à En maintenance',
          Icons.door_front_door,
          Colors.orange,
        );

        // Simuler l'envoi de l'information au backend
        _sendStatusUpdateToBackend();
      }
    });
  }

  // Fonction pour simuler la fermeture du distributeur
  void _simulateDoorClose() {
    setState(() {
      _isSimulatorOpen = false;

      // Remettre l'état du distributeur à opérationnel
      if (_machine['status'] == 'En maintenance' &&
          _machine['issue'] == 'Porte ouverte - Accès de maintenance') {
        _machine['status'] = 'Opérationnel';
        _machine.remove('issue');

        // Ajouter cet événement aux activités récentes
        _addActivity(
          'Distributeur fermé',
          '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} - Retour à l\'état opérationnel',
          Icons.door_back_door,
          Colors.green,
        );

        // Simuler l'envoi de l'information au backend
        _sendStatusUpdateToBackend();
      }
    });
  }

  // Fonction pour simuler l'envoi d'informations au backend
  void _sendStatusUpdateToBackend() {
    // Simuler une communication avec le backend
    setState(() {
      _isRefreshing = true;
    });

    // Simuler un délai de communication réseau
    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() {
        _isRefreshing = false;
      });

      // Afficher un message de confirmation
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Statut synchronisé avec le système central'),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 2),
        ),
      );
    });
  }
}
