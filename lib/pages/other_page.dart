import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:new_flutter/widgets/app_layout.dart';
import 'package:new_flutter/models/event.dart';
import 'package:new_flutter/services/events_service.dart';
import 'package:new_flutter/widgets/export_button.dart';
import 'package:new_flutter/widgets/clickable_contact_info.dart';
import 'package:new_flutter/widgets/file_preview_widget.dart';

class OtherPage extends StatefulWidget {
  const OtherPage({super.key});

  @override
  State<OtherPage> createState() => _OtherPageState();
}

class _OtherPageState extends State<OtherPage> {
  List<Event> _otherEvents = [];
  List<Event> _filteredOtherEvents = [];
  bool _isLoading = true;
  bool _isGridView = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final EventsService _eventsService = EventsService();

  @override
  void initState() {
    super.initState();
    _loadOtherEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOtherEvents() async {
    if (!mounted) return;
    debugPrint(
        '🔄 OtherPage._loadOtherEvents() - Starting to load other events...');
    setState(() => _isLoading = true);
    try {
      final allEvents = await _eventsService.getEvents();
      final otherEvents =
          allEvents.where((event) => event.type == EventType.other).toList();
      debugPrint(
          '🔄 OtherPage._loadOtherEvents() - Loaded ${otherEvents.length} other events');
      if (!mounted) return;
      setState(() {
        _otherEvents = otherEvents;
        _filteredOtherEvents = otherEvents;
        _isLoading = false;
      });
      _applyFilters();
      debugPrint(
          '🔄 OtherPage._loadOtherEvents() - Applied filters, showing ${_filteredOtherEvents.length} other events');
    } catch (e) {
      debugPrint('❌ OtherPage._loadOtherEvents() - Error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading other events: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    if (!mounted) return;
    setState(() {
      _filteredOtherEvents = _otherEvents.where((event) {
        final searchLower = _searchQuery.toLowerCase();
        return (event.clientName?.toLowerCase().contains(searchLower) ??
                false) ||
            (event.location?.toLowerCase().contains(searchLower) ?? false) ||
            (event.notes?.toLowerCase().contains(searchLower) ?? false) ||
            (event.additionalData?['event_name']
                    ?.toLowerCase()
                    .contains(searchLower) ??
                false);
      }).toList();

      _filteredOtherEvents.sort((a, b) {
        final dateA = a.date ?? DateTime(1900);
        final dateB = b.date ?? DateTime(1900);
        return dateB.compareTo(dateA);
      });
    });
  }

  void _onSearchChanged(String query) {
    if (!mounted) return;
    setState(() => _searchQuery = query);
    _applyFilters();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'No Date';
    return DateFormat('MMM d, yyyy').format(date);
  }

  Widget _buildContent() {
    if (_filteredOtherEvents.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: _isGridView ? _buildGridView() : _buildListView(),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.more_horiz,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No other events found',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first other event to get started',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.pushNamed(
                context,
                '/new-event',
                arguments: {'eventType': EventType.other},
              );
              if (result == true && mounted) {
                _loadOtherEvents();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Add New Other Event'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: const InputDecoration(
          hintText: 'Search other events...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      currentPage: '/other',
      title: 'Other Events',
      actions: [
        // Export button
        ExportButton(
          type: ExportType.events,
          data: _filteredOtherEvents,
          customFilename:
              'other_events_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.csv',
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
          onPressed: () {
            if (mounted) setState(() => _isGridView = !_isGridView);
          },
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () async {
            final result = await Navigator.pushNamed(
              context,
              '/new-event',
              arguments: {'eventType': EventType.other},
            );
            if (result == true && mounted) {
              _loadOtherEvents();
            }
          },
        ),
      ],
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildGridView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 1;
        double childAspectRatio =
            0.75; // Taller cards for mobile to accommodate files

        if (constraints.maxWidth > 600) {
          crossAxisCount = 2;
          childAspectRatio = 0.85;
        }
        if (constraints.maxWidth > 900) {
          crossAxisCount = 3;
          childAspectRatio = 0.95;
        }
        if (constraints.maxWidth > 1200) {
          crossAxisCount = 4;
          childAspectRatio = 1.0;
        }

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _filteredOtherEvents.length,
          itemBuilder: (context, index) {
            final event = _filteredOtherEvents[index];
            return _buildEventCard(event);
          },
        );
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredOtherEvents.length,
      itemBuilder: (context, index) {
        final event = _filteredOtherEvents[index];
        return _buildEventListItem(event);
      },
    );
  }

  Widget _buildEventCard(Event event) {
    final eventName = event.additionalData?['event_name'] ??
        event.clientName ??
        'Unnamed Event';
    final dateStr = _formatDate(event.date);

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _editEvent(event),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with title and menu
              Row(
                children: [
                  Expanded(
                    child: Text(
                      eventName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    iconSize: 18,
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editEvent(event);
                      } else if (value == 'delete') {
                        _deleteEvent(event);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Location (if available)
              if (event.location != null) ...[
                ClickableContactInfo(
                  text: event.location!,
                  type: ContactType.location,
                  iconColor: Colors.grey,
                  textColor: Colors.blue[400],
                  fontSize: 12,
                ),
                const SizedBox(height: 4),
              ],

              // Date
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      dateStr,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // Time (if available)
              if (event.startTime != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      event.startTime!,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],

              // File attachments section
              Builder(
                builder: (context) {
                  // Check for files in event.additionalData.file_data
                  Map<String, dynamic>? fileData;

                  if (event.additionalData != null &&
                      event.additionalData!.containsKey('file_data') &&
                      event.additionalData!['file_data']
                          is Map<String, dynamic>) {
                    fileData = event.additionalData!['file_data']
                        as Map<String, dynamic>;
                  }

                  // If no files found, return empty widget
                  if (fileData == null ||
                      !fileData.containsKey('files') ||
                      fileData['files'] is! List ||
                      (fileData['files'] as List).isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    children: [
                      const SizedBox(height: 6),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final filesList = fileData!['files'] as List;

                          // For very small cards, show just a compact indicator
                          if (constraints.maxHeight < 200) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.grey[800]?.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.attach_file,
                                      size: 10, color: Colors.grey),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${filesList.length} file${filesList.length > 1 ? 's' : ''}',
                                    style: const TextStyle(
                                        fontSize: 9, color: Colors.grey),
                                  ),
                                ],
                              ),
                            );
                          }

                          // For larger cards, show the full FilePreviewWidget
                          return FilePreviewWidget(
                            fileData: fileData,
                            showTitle: false, // Hide title to save space
                            maxFilesToShow: 1,
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventListItem(Event event) {
    final eventName = event.additionalData?['event_name'] ??
        event.clientName ??
        'Unnamed Event';
    final dateStr = _formatDate(event.date);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => _editEvent(event),
        leading: const CircleAvatar(
          backgroundColor: Colors.orange,
          child: Icon(Icons.more_horiz, color: Colors.white),
        ),
        title: Text(
          eventName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.location != null) ...[
              ClickableContactInfo(
                text: event.location!,
                type: ContactType.location,
                iconColor: Colors.grey,
                textColor: Colors.blue[400],
                fontSize: 14,
              ),
            ],
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  dateStr,
                  style: const TextStyle(color: Colors.grey),
                ),
                if (event.startTime != null) ...[
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    event.startTime!,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ],
            ),
            // File attachments indicator
            Builder(
              builder: (context) {
                // Check for files in event.additionalData.file_data
                Map<String, dynamic>? fileData;

                if (event.additionalData != null &&
                    event.additionalData!.containsKey('file_data') &&
                    event.additionalData!['file_data']
                        is Map<String, dynamic>) {
                  fileData = event.additionalData!['file_data']
                      as Map<String, dynamic>;
                }

                // If no files found, return empty widget
                if (fileData == null ||
                    !fileData.containsKey('files') ||
                    fileData['files'] is! List ||
                    (fileData['files'] as List).isEmpty) {
                  return const SizedBox.shrink();
                }

                final filesList = fileData['files'] as List;
                return Column(
                  children: [
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.attach_file,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${filesList.length} file${filesList.length > 1 ? 's' : ''}',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _editEvent(event);
            } else if (value == 'delete') {
              _deleteEvent(event);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Text('Edit'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }

  void _editEvent(Event event) async {
    final result = await Navigator.pushNamed(
      context,
      '/new-event',
      arguments: {
        'eventType': EventType.other,
        'event': event,
      },
    );
    if (result == true && mounted) {
      _loadOtherEvents();
    }
  }

  void _deleteEvent(Event event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text(
            'Are you sure you want to delete "${event.additionalData?['event_name'] ?? event.clientName ?? 'this event'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && event.id != null) {
      try {
        final success = await _eventsService.deleteEvent(event.id!);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event deleted successfully')),
          );
          _loadOtherEvents();
        } else {
          throw Exception('Failed to delete event');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting event: $e')),
          );
        }
      }
    }
  }
}
