import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/test.dart';
import '../providers/tests_provider.dart';
import '../widgets/app_layout.dart';
import '../widgets/ui/badge.dart' as ui;
import '../widgets/ui/input.dart' as ui;
import '../widgets/ui/button.dart';
import '../widgets/ui/table.dart' as ui;
import '../widgets/export_button.dart';
import '../widgets/clickable_contact_info.dart';
import '../theme/app_theme.dart';

class TestsPage extends StatefulWidget {
  const TestsPage({super.key});

  @override
  State<TestsPage> createState() => _TestsPageState();
}

class _TestsPageState extends State<TestsPage> {
  String _viewMode = 'grid';
  String _selectedStatus = 'all';
  final _searchController = TextEditingController();
  final Map<String, bool> _columnVisibility = {
    'date': true,
    'title': true,
    'description': true,
    'location': true,
    'status': true,
    'rate': true,
    'actions': true,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TestsProvider>().loadTests();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFEF9C3); // yellow-100
      case 'confirmed':
        return const Color(0xFFDBEAFE); // blue-100
      case 'completed':
        return const Color(0xFFDCFCE7); // green-100
      case 'rejected':
        return const Color(0xFFFEE2E2); // red-100
      case 'canceled':
        return const Color(0xFFF3F4F6); // gray-100
      default:
        return const Color(0xFFF3F4F6); // gray-100
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFF854D0E); // yellow-800
      case 'confirmed':
        return const Color(0xFF1E40AF); // blue-800
      case 'completed':
        return const Color(0xFF166534); // green-800
      case 'rejected':
        return const Color(0xFF991B1B); // red-800
      case 'canceled':
        return const Color(0xFF1F2937); // gray-800
      default:
        return const Color(0xFF1F2937); // gray-800
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context, Test test) async {
    if (!mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final provider = context.read<TestsProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Delete Test',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "${test.title}"? This action cannot be undone.',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (confirmed == true) {
      final success = await provider.deleteTest(test.id);

      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Test deleted successfully'
                : provider.error ?? 'Error deleting test'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showFilterDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Filter Tests',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Filter by Status:',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                'all',
                'pending',
                'confirmed',
                'completed',
                'rejected',
                'canceled'
              ]
                  .map((status) => FilterChip(
                        label: Text(status.toUpperCase()),
                        selected: _selectedStatus == status,
                        onSelected: (selected) {
                          setState(() {
                            _selectedStatus = selected ? status : 'all';
                          });
                          Navigator.pop(context);
                          // Filter will be applied automatically through provider
                        },
                      ))
                  .toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildTestCard(Test test) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                      test.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    iconSize: 18,
                    onSelected: (value) {
                      if (value == 'edit') {
                        Navigator.pushNamed(
                          context,
                          '/new-test',
                          arguments: test,
                        ).then((result) {
                          if (result == true && mounted) {
                            context.read<TestsProvider>().loadTests();
                          }
                        });
                      } else if (value == 'delete') {
                        _showDeleteConfirmation(context, test);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 16, color: Colors.orange),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    icon: const Icon(
                      Icons.more_vert,
                      size: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Status chip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(test.status),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  test.status.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusTextColor(test.status),
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Description
              if (test.description != null)
                Text(
                  test.description!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 8),

              // Date and Rate in compact row
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM d').format(test.date),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (test.rate != null) ...[
                    const SizedBox(width: 16),
                    const Icon(Icons.attach_money, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${test.currency ?? 'USD'} ${test.rate!.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),

              // Location
              if (test.location != null)
                ClickableContactInfo(
                  text: test.location!,
                  type: ContactType.location,
                  iconColor: Colors.grey,
                  textColor: Colors.blue[400],
                  fontSize: 12,
                ),
            ],
          ),
        ),
    );
  }

  Widget _buildTestsTable(TestsProvider provider) {
    return ui.Table(
      children: [
        ui.TableHead(
          children: [
            if (_columnVisibility['date']!)
              const ui.TableHeader(child: Text('Date')),
            if (_columnVisibility['title']!)
              const ui.TableHeader(child: Text('Title')),
            if (_columnVisibility['description']!)
              const ui.TableHeader(child: Text('Description')),
            if (_columnVisibility['location']!)
              const ui.TableHeader(child: Text('Location')),
            if (_columnVisibility['status']!)
              const ui.TableHeader(child: Text('Status')),
            if (_columnVisibility['rate']!)
              const ui.TableHeader(child: Text('Rate')),
            if (_columnVisibility['actions']!)
              const ui.TableHeader(child: Text('Actions')),
          ],
        ),
        ui.TableBody(
          children: provider.filteredTests.map((test) {
            return ui.TableRow(
              children: [
                if (_columnVisibility['date']!)
                  ui.TableCell(
                    child: Text(
                      DateFormat('MMM d, yyyy').format(test.date),
                    ),
                  ),
                if (_columnVisibility['title']!)
                  ui.TableCell(child: Text(test.title)),
                if (_columnVisibility['description']!)
                  ui.TableCell(
                    child: Text(
                      test.description ?? 'No description',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (_columnVisibility['location']!)
                  ui.TableCell(
                    child: test.location != null
                        ? ClickableContactInfo(
                            text: test.location!,
                            type: ContactType.location,
                            showIcon: false,
                            textColor: Colors.blue[400],
                            fontSize: 12,
                          )
                        : const Text('No location'),
                  ),
                if (_columnVisibility['status']!)
                  ui.TableCell(
                    child: ui.Badge(
                      label: test.status,
                      backgroundColor: _getStatusColor(test.status),
                      textColor: _getStatusTextColor(test.status),
                      variant: ui.BadgeVariant.outline,
                    ),
                  ),
                if (_columnVisibility['rate']!)
                  ui.TableCell(
                    child: test.rate != null
                        ? Text(
                            '${test.currency ?? 'USD'} ${test.rate!.toStringAsFixed(2)}',
                          )
                        : const Text('-'),
                  ),
                if (_columnVisibility['actions']!)
                  ui.TableCell(
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () async {
                            final result = await Navigator.pushNamed(
                              context,
                              '/new-test',
                              arguments: test,
                            );
                            if (result == true && mounted) {
                              context.read<TestsProvider>().loadTests();
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () =>
                              _showDeleteConfirmation(context, test),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.science,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'No tests found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first test to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.pushNamed(context, '/new-test');
              if (result == true && mounted) {
                context.read<TestsProvider>().loadTests();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Test'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.goldColor,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TestsProvider>(
      builder: (context, provider, child) {
        return AppLayout(
          currentPage: '/tests',
          title: 'Tests',
          actions: [
            // Export button
            ExportButton(
              type: ExportType.tests,
              data: provider.filteredTests,
              customFilename: 'tests_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.csv',
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final result = await Navigator.pushNamed(context, '/new-test');
                if (result == true) {
                  provider.loadTests();
                }
              },
            ),
          ],
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ui.Input(
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'Search tests...',
                        controller: _searchController,
                        onChanged: (value) => provider.setSearchTerm(value),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Button(
                      text: 'Filter',
                      variant: ButtonVariant.outline,
                      prefix: const Icon(Icons.filter_list),
                      onPressed: () => _showFilterDialog(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        _viewMode == 'grid' ? Icons.view_list : Icons.grid_view,
                      ),
                      onPressed: () {
                        setState(() {
                          _viewMode = _viewMode == 'grid' ? 'list' : 'grid';
                        });
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: provider.refresh,
                  child: provider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : provider.error != null
                          ? Center(child: Text(provider.error!))
                          : provider.filteredTests.isEmpty
                              ? _buildEmptyState()
                              : _viewMode == 'grid'
                                  ? LayoutBuilder(
                                      builder: (context, constraints) {
                                        int crossAxisCount = 4;
                                        if (constraints.maxWidth < 1200) {
                                          crossAxisCount = 3;
                                        }
                                        if (constraints.maxWidth < 900) {
                                          crossAxisCount = 2;
                                        }
                                        if (constraints.maxWidth < 600) {
                                          crossAxisCount = 1;
                                        }

                                        return GridView.builder(
                                          padding: const EdgeInsets.all(12),
                                          gridDelegate:
                                              SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: crossAxisCount,
                                            crossAxisSpacing: 12,
                                            mainAxisSpacing: 12,
                                            childAspectRatio: 1.1,
                                          ),
                                          itemCount:
                                              provider.filteredTests.length,
                                          itemBuilder: (context, index) =>
                                              _buildTestCard(provider
                                                  .filteredTests[index]),
                                        );
                                      },
                                    )
                                  : SingleChildScrollView(
                                      padding: const EdgeInsets.all(16),
                                      child: _buildTestsTable(provider),
                                    ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
