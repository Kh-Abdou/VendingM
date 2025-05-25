import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/hardware_provider.dart'; // For temperature and humidity data

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

  // Environment data state
  bool _isLoadingEnvironment = false;
  String? _environmentError;

  // Timer for auto-refreshing environment data
  Timer? _environmentRefreshTimer; // Données du distributeur
  Map<String, dynamic> _machine = {
    'id': 1,
    'status': 'Opérationnel',
  };
  // Liste des statuts possibles
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

    // Load environment data on startup
    _loadEnvironmentData();

    // Set up a timer to refresh environment data every 30 seconds
    _environmentRefreshTimer =
        Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadEnvironmentData();
      }
    });

    // Update machine data from the first environment data entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateMachineDataFromProvider();
    });
  }

  // Update machine data from environment data provider
  void _updateMachineDataFromProvider() {
    final hardwareProvider =
        Provider.of<HardwareProvider>(context, listen: false);
    if (hardwareProvider.environmentData.isNotEmpty) {
      final envData = hardwareProvider.environmentData[0];
      setState(() {
        _machine = {
          'id': envData['vendingMachineId'] ?? 1,
          'status': _convertHardwareStatus(envData['status'] ?? 'UNKNOWN'),
          'lastSensorUpdate': envData['lastCommunication'],
        };
      });
    }
  }

  // Convert hardware status from backend format to UI format
  String _convertHardwareStatus(String backendStatus) {
    switch (backendStatus) {
      case 'OPERATIONAL':
        return 'Opérationnel';
      case 'MAINTENANCE':
        return 'En maintenance';
      case 'ERROR':
        return 'En panne';
      case 'OFFLINE':
        return 'Hors service';
      default:
        return 'Opérationnel';
    }
  }

  @override
  void dispose() {
    _environmentRefreshTimer?.cancel();
    super.dispose();
  }

  // Load environment data from hardware provider
  Future<void> _loadEnvironmentData() async {
    if (!mounted) return;

    setState(() {
      _isLoadingEnvironment = true;
      _environmentError = null;
    });

    try {
      print('🔄 Loading environment data...');
      final hardwareProvider =
          Provider.of<HardwareProvider>(context, listen: false);
      await hardwareProvider.loadEnvironmentData();

      if (!mounted) return;

      setState(() {
        _isLoadingEnvironment = false;
      });

      // Update machine data when environment data is loaded
      _updateMachineDataFromProvider();
    } catch (e) {
      print('❌ Error loading environment data: $e');

      if (!mounted) return;

      setState(() {
        _isLoadingEnvironment = false;
        _environmentError = e.toString();
      });
    }
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
                  style: TextStyle(
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
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Dernière mise à jour: ${_formatLastUpdate(_machine['lastSensorUpdate'] as String?)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
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

                // Environment data card
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildEnvironmentDataCard(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _refreshMachineStatus() {
    setState(() {
      _isRefreshing = true;
    });

    // Refresh environment data (which will also update machine data)
    _loadEnvironmentData().then((_) {
      // Delay slightly to give time for data to update
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
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
    }).catchError((e) {
      setState(() {
        _isRefreshing = false;
      });

      // Show error message
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'actualisation: ${e.toString()}'),
          backgroundColor: Colors.red,
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

  String _formatLastUpdate(String? timestamp) {
    if (timestamp == null) return 'Non disponible';

    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'À l\'instant';
      } else if (difference.inHours < 1) {
        return 'Il y a ${difference.inMinutes} minutes';
      } else if (difference.inDays < 1) {
        return 'Il y a ${difference.inHours} heures';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return 'Format invalide';
    }
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
    IconData iconData = Icons.help; // Default value
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
  } // Widget to display environment data

  Widget _buildEnvironmentDataCard() {
    return Consumer<HardwareProvider>(
      builder: (context, hardwareProvider, child) {
        if (_isLoadingEnvironment) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircularProgressIndicator(
                    color: widget.primaryColor,
                  ),
                  const SizedBox(height: 16),
                  const Text('Chargement des données environnementales...'),
                ],
              ),
            ),
          );
        }

        if (_environmentError != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Erreur: $_environmentError'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadEnvironmentData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.buttonColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Get data from the hardware provider
        final environmentData = hardwareProvider.environmentData.isNotEmpty
            ? hardwareProvider.environmentData[0]
            : <String, dynamic>{
                'temperature': null,
                'humidity': null,
                'lastCommunication': null
              };

        // Get timestamp and connection status
        final DateTime lastUpdate = environmentData['lastCommunication'] != null
            ? DateTime.parse(environmentData['lastCommunication'].toString())
            : DateTime.now().subtract(const Duration(
                hours: 2)); // Ensure it appears offline if no data
        final String connectionStatus = _getConnectionStatusText(lastUpdate);
        final Color connectionColor = _getConnectionStatusColor(lastUpdate);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.thermostat_outlined, color: widget.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Données Environnementales',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: widget.primaryColor,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.circle, size: 12, color: connectionColor),
                    const SizedBox(width: 6),
                    Text(
                      connectionStatus,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildEnvironmentValue(
                  'Température',
                  environmentData['temperature'] != null
                      ? '${environmentData['temperature']} °C'
                      : 'N/A',
                  icon: Icons.thermostat,
                  isAlert: environmentData['temperature'] != null &&
                      (environmentData['temperature'] > 30 ||
                          environmentData['temperature'] < 10),
                ),
                _buildEnvironmentValue(
                  'Humidité',
                  environmentData['humidity'] != null
                      ? '${environmentData['humidity']} %'
                      : 'N/A',
                  icon: Icons.water_drop,
                  isAlert: environmentData['humidity'] != null &&
                      (environmentData['humidity'] > 70 ||
                          environmentData['humidity'] < 20),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // Helper widget for environment values
  Widget _buildEnvironmentValue(String label, String value,
      {required IconData icon, bool isAlert = false}) {
    final Color valueColor = isAlert ? Colors.red : Colors.black87;

    return Expanded(
      child: Card(
        elevation: 0,
        color: Theme.of(context).cardColor.withOpacity(0.7),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: widget.primaryColor, size: 30),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Show all environment data in a dialog
  void _showAllEnvironmentData(List<Map<String, dynamic>> environmentData) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.history, color: widget.primaryColor),
              const SizedBox(width: 10),
              const Text('Historique des données'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: environmentData.length,
              itemBuilder: (context, index) {
                final data = environmentData[index];
                final DateTime timestamp = data['timestamp'] as DateTime;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDate(timestamp),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: DefaultTextStyle.of(context).style,
                                  children: [
                                    const TextSpan(
                                      text: 'Température: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(
                                      text: data['temperature'] != null
                                          ? '${data['temperature']} °C'
                                          : 'N/A',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: DefaultTextStyle.of(context).style,
                                  children: [
                                    const TextSpan(
                                      text: 'Humidité: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(
                                      text: data['humidity'] != null
                                          ? '${data['humidity']} %'
                                          : 'N/A',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  // Helper method to format date
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Helper method to determine connection status color based on last update time
  Color _getConnectionStatusColor(DateTime lastUpdate) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdate);

    if (difference.inMinutes < 5) {
      return Colors.green; // Online - recently updated
    } else if (difference.inHours < 1) {
      return Colors.orange; // Stale - updated within the last hour
    } else {
      return Colors.red; // Offline - not updated for more than an hour
    }
  }

  // Helper method to get connection status text based on last update time
  String _getConnectionStatusText(DateTime lastUpdate) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdate);

    if (difference.inMinutes < 5) {
      return '';
    } else if (difference.inHours < 1) {
      return 'Mis à jour il y a ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'Mis à jour il y a ${difference.inHours} h';
    } else {
      return '';
    }
  }
}
