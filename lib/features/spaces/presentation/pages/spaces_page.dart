import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/space.dart';
import '../../domain/repositories/spaces_repository.dart';
import '../bloc/spaces_bloc.dart';
import '../../../inventory/presentation/widgets/space_picker_widget.dart';

class SpacesPage extends StatelessWidget {
  const SpacesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SpacesBloc>()..add(LoadParentSpaces()),
      child: const _SpacesView(),
    );
  }
}

class _SpacesView extends StatefulWidget {
  const _SpacesView();

  @override
  State<_SpacesView> createState() => _SpacesViewState();
}

class _SpacesViewState extends State<_SpacesView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: BlocConsumer<SpacesBloc, SpacesState>(
                listener: (context, state) {
                  if (state is SpacesError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async {
                      final bloc = context.read<SpacesBloc>();
                      final currentState = bloc.state;
                      if (currentState is SpacesLoaded && currentState.currentParent != null) {
                        // Reload children in-place without pushing stack
                        bloc.add(LoadParentSpaces()); // will be overridden below
                      }
                      // Simple: just reload current view
                      if (currentState is SpacesLoaded && currentState.currentParent != null) {
                        // We can't easily reload in-place via event, so just re-enter
                        // But that would push stack. Instead, use GoBackOneLevel + re-enter?
                        // Simplest: reload parents
                      }
                      bloc.add(LoadParentSpaces());
                      await Future.delayed(const Duration(milliseconds: 800));
                    },
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(child: _buildSearchBar(context)),
                        SliverToBoxAdapter(child: _buildFilterChips(context)),
                        SliverToBoxAdapter(child: _buildBreadcrumb(context)),
                        SliverToBoxAdapter(child: _buildResultsCount(context)),
                        _buildSpacesList(context),
                        const SliverToBoxAdapter(child: SizedBox(height: 100)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSpaceDialog(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Adaugă Locație',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // ─── HEADER ───────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Spații & Locații',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Gestionează locațiile bunurilor',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                ),
              ],
            ),
          ),
          BlocBuilder<SpacesBloc, SpacesState>(
            builder: (context, state) {
              if (state is SpacesLoaded && state.currentParent != null) {
                return Material(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      _searchController.clear();
                      context.read<SpacesBloc>().add(GoBackOneLevel());
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary, size: 22),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  // ─── SEARCH BAR ──────────────────────────────────────────────
  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {});
          context.read<SpacesBloc>().add(SearchSpaces(value));
        },
        decoration: InputDecoration(
          hintText: 'Caută locații...',
          hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint, size: 22),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textHint, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                    context.read<SpacesBloc>().add(const SearchSpaces(''));
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  // ─── FILTER CHIPS ────────────────────────────────────────────
  Widget _buildFilterChips(BuildContext context) {
    return BlocBuilder<SpacesBloc, SpacesState>(
      builder: (context, state) {
        final selectedType = state is SpacesLoaded ? state.selectedType : null;
        return SizedBox(
          height: 46,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              _TypeChip(
                label: 'Toate',
                isSelected: selectedType == null,
                onTap: () => context.read<SpacesBloc>().add(const FilterByType(null)),
              ),
              const SizedBox(width: 8),
              _TypeChip(
                label: 'Casă',
                emoji: '🏠',
                isSelected: selectedType == SpaceType.home,
                onTap: () => context.read<SpacesBloc>().add(const FilterByType(SpaceType.home)),
              ),
              const SizedBox(width: 8),
              _TypeChip(
                label: 'Birou',
                emoji: '🏢',
                isSelected: selectedType == SpaceType.office,
                onTap: () => context.read<SpacesBloc>().add(const FilterByType(SpaceType.office)),
              ),
              const SizedBox(width: 8),
              _TypeChip(
                label: 'Cameră',
                emoji: '🚪',
                isSelected: selectedType == SpaceType.room,
                onTap: () => context.read<SpacesBloc>().add(const FilterByType(SpaceType.room)),
              ),
              const SizedBox(width: 8),
              _TypeChip(
                label: 'Depozit',
                emoji: '📦',
                isSelected: selectedType == SpaceType.storage,
                onTap: () => context.read<SpacesBloc>().add(const FilterByType(SpaceType.storage)),
              ),
              const SizedBox(width: 8),
              _TypeChip(
                label: 'Altele',
                emoji: '📍',
                isSelected: selectedType == SpaceType.other,
                onTap: () => context.read<SpacesBloc>().add(const FilterByType(SpaceType.other)),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── BREADCRUMB ──────────────────────────────────────────────
  Widget _buildBreadcrumb(BuildContext context) {
    return BlocBuilder<SpacesBloc, SpacesState>(
      builder: (context, state) {
        if (state is! SpacesLoaded || state.parentStack.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      // Go all the way back to root
                      context.read<SpacesBloc>().add(LoadParentSpaces());
                    },
                    child: const Text(
                      '📍 Locații',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  // Show each level in the stack
                  ...state.parentStack.map((parent) {
                    final isLast = parent == state.parentStack.last;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textHint),
                        ),
                        GestureDetector(
                          onTap: isLast
                              ? null
                              : () {
                                  _searchController.clear();
                                  // Navigate to this specific level by rebuilding the stack
                                  final idx = state.parentStack.indexOf(parent);
                                  // Go back to root then re-enter up to this level
                                  // Simplest: use LoadParentSpaces then re-enter
                                  // But we need the bloc to handle this...
                                  // For now, just go back levels
                                  final levelsToGoBack = state.parentStack.length - idx - 1;
                                  for (int i = 0; i < levelsToGoBack; i++) {
                                    context.read<SpacesBloc>().add(GoBackOneLevel());
                                  }
                                },
                          child: Text(
                            '${parent.typeEmoji} ${parent.name}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: isLast ? AppColors.textPrimary : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── RESULTS COUNT ───────────────────────────────────────────
  Widget _buildResultsCount(BuildContext context) {
    return BlocBuilder<SpacesBloc, SpacesState>(
      builder: (context, state) {
        if (state is! SpacesLoaded) return const SizedBox.shrink();
        final count = state.filteredSpaces.length;
        final label = state.isViewingChildren ? 'sublocații' : 'locații';
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
          child: Text(
            '$count $label găsite',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
          ),
        );
      },
    );
  }

  // ─── SPACES LIST ─────────────────────────────────────────────
  Widget _buildSpacesList(BuildContext context) {
    return BlocBuilder<SpacesBloc, SpacesState>(
      builder: (context, state) {
        if (state is SpacesLoading) {
          return const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (state is SpacesError) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline_rounded, size: 64, color: AppColors.error.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(state.message, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.read<SpacesBloc>().add(LoadParentSpaces()),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Reîncearcă'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is SpacesLoaded) {
          if (state.filteredSpaces.isEmpty) {
            return SliverFillRemaining(
              child: _buildEmptyState(context, state.isViewingChildren),
            );
          }

          return SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _SpaceCard(
                  space: state.filteredSpaces[index],
                  onTap: (space) {
                    _searchController.clear();
                    context.read<SpacesBloc>().add(LoadChildrenSpaces(space));
                  },
                  onEdit: (space) => _showEditSpaceDialog(context, space),
                  onDelete: (space) => _showDeleteConfirmation(context, space),
                ),
                childCount: state.filteredSpaces.length,
              ),
            ),
          );
        }

        return const SliverToBoxAdapter(child: SizedBox.shrink());
      },
    );
  }

  // ─── EMPTY STATE ─────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context, bool isChildren) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Center(
                child: Text(
                  isChildren ? '📂' : '🏠',
                  style: const TextStyle(fontSize: 48),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isChildren ? 'Nu există sublocații' : 'Nu există locații',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              isChildren
                  ? 'Adaugă o sublocație pentru acest spațiu'
                  : 'Adaugă prima ta locație pentru a organiza bunurile',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => _showAddSpaceDialog(context),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text(
                isChildren ? 'Adaugă sublocație' : 'Adaugă prima locație',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── ADD SPACE DIALOG ────────────────────────────────────────
  void _showAddSpaceDialog(BuildContext context) {
    final bloc = context.read<SpacesBloc>();
    final currentState = bloc.state;
    final nameController = TextEditingController();
    SpaceType selectedType = SpaceType.room;

    // Use SpacePickerWidget instead of cascading dropdowns
    SelectedSpace? selectedParentSpace;

    // Pre-select parent if currently viewing children
    if (currentState is SpacesLoaded && currentState.parentStack.isNotEmpty) {
      final lastParent = currentState.parentStack.last;
      selectedParentSpace = SelectedSpace(
        id: lastParent.id,
        name: lastParent.name,
        type: lastParent.type,
        fullPath: currentState.parentStack.map((s) => s.name).join(' > '),
      );
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.add_location_alt_rounded, color: AppColors.primary, size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Adaugă Locație',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.background,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name
                          TextField(
                            controller: nameController,
                            decoration: InputDecoration(
                              labelText: 'Denumire',
                              hintText: 'ex: Living, Birou principal...',
                              hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
                              prefixIcon: const Icon(Icons.label_outline_rounded, color: AppColors.textHint),
                              filled: true,
                              fillColor: AppColors.background,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Parent selector - using SpacePickerWidget
                          const Text(
                            'LOCAȚIE PĂRINTE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // "No parent" option
                          GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedParentSpace = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: selectedParentSpace == null
                                    ? AppColors.primary.withValues(alpha: 0.08)
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selectedParentSpace == null
                                      ? AppColors.primary
                                      : AppColors.divider.withValues(alpha: 0.5),
                                  width: selectedParentSpace == null ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Text('🌐', style: TextStyle(fontSize: 16)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Fără părinte (locație principală)',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: selectedParentSpace == null ? FontWeight.w600 : FontWeight.w400,
                                        color: selectedParentSpace == null ? AppColors.primary : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  if (selectedParentSpace == null)
                                    const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
                                ],
                              ),
                            ),
                          ),

                          // SpacePickerWidget
                          SpacePickerWidget(
                            initialValue: selectedParentSpace,
                            onChanged: (space) {
                              setModalState(() {
                                selectedParentSpace = space;
                              });
                            },
                          ),

                          // Display selected path
                          if (selectedParentSpace != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Părinte: ${selectedParentSpace!.fullPath ?? selectedParentSpace!.name}',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 16),
                          // Type
                          const Text(
                            'TIP LOCAȚIE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: SpaceType.values.map((type) {
                              final space = Space(id: 0, name: '', type: type);
                              return GestureDetector(
                                onTap: () => setModalState(() => selectedType = type),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: selectedType == type
                                        ? AppColors.primary.withValues(alpha: 0.08)
                                        : AppColors.background,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: selectedType == type
                                          ? AppColors.primary
                                          : AppColors.divider.withValues(alpha: 0.5),
                                      width: selectedType == type ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(space.typeEmoji, style: const TextStyle(fontSize: 16)),
                                      const SizedBox(width: 6),
                                      Text(
                                        space.typeLabel,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: selectedType == type ? FontWeight.w600 : FontWeight.w500,
                                          color: selectedType == type ? AppColors.primary : AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  // Actions
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                              side: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Anulează'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (nameController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Introdu o denumire'),
                                    backgroundColor: AppColors.warning,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                                return;
                              }
                              bloc.add(CreateSpaceEvent(
                                name: nameController.text.trim(),
                                type: selectedType,
                                parentSpaceId: selectedParentSpace?.id,
                              ));
                              Navigator.pop(ctx);
                            },
                            icon: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                            label: const Text('Salvează', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
            );
          },
        ),
      );
    }
  }

  // ─── EDIT SPACE DIALOG ───────────────────────────────────────
  void _showEditSpaceDialog(BuildContext context, Space space) {
    final bloc = context.read<SpacesBloc>();
    final nameController = TextEditingController(text: space.name);
    SpaceType selectedType = space.type;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.edit_location_alt_rounded, color: AppColors.primary, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Editează Locația',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.background,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Denumire',
                          hintText: 'ex: Living, Birou principal...',
                          hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
                          prefixIcon: const Icon(Icons.label_outline_rounded, color: AppColors.textHint),
                          filled: true,
                          fillColor: AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'TIP LOCAȚIE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: SpaceType.values.map((type) {
                          final tempSpace = Space(id: 0, name: '', type: type);
                          return GestureDetector(
                            onTap: () => setModalState(() => selectedType = type),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: selectedType == type
                                    ? AppColors.primary.withValues(alpha: 0.08)
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selectedType == type
                                      ? AppColors.primary
                                      : AppColors.divider.withValues(alpha: 0.5),
                                  width: selectedType == type ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(tempSpace.typeEmoji, style: const TextStyle(fontSize: 16)),
                                  const SizedBox(width: 6),
                                  Text(
                                    tempSpace.typeLabel,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: selectedType == type ? FontWeight.w600 : FontWeight.w500,
                                      color: selectedType == type ? AppColors.primary : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Anulează'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (nameController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Introdu o denumire'),
                                  backgroundColor: AppColors.warning,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                              return;
                            }
                            bloc.add(UpdateSpaceEvent(
                              spaceId: space.id,
                              name: nameController.text.trim(),
                              type: selectedType,
                            ));
                            Navigator.pop(ctx);
                          },
                          icon: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                          label: const Text('Salvează', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      );
    }


  // ─── DELETE CONFIRMATION ─────────────────────────────────────
  void _showDeleteConfirmation(BuildContext context, Space space) {
    final bloc = context.read<SpacesBloc>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Șterge Locația')),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            children: [
              const TextSpan(text: 'Ești sigur că vrei să ștergi locația '),
              TextSpan(
                text: '"${space.name}"',
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const TextSpan(text: '? Această acțiune nu poate fi anulată.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Anulează', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              bloc.add(DeleteSpaceEvent(space.id));
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Șterge', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _preselectLevels(
    List<Space> parentStack,
    List<_SpaceOptionItem> parents,
    List<List<_SpaceOptionItem>> spaceLevels,
    List<_SpaceOptionItem?> selectedAtLevel,
    List<bool> loadingAtLevel,
    StateSetter setModalState,
  ) {
    // Pre-select the first level based on the parent stack
    if (parentStack.isNotEmpty && spaceLevels.isNotEmpty) {
      final firstParent = parentStack[0];
      _SpaceOptionItem? found;
      for (final item in spaceLevels[0]) {
        if (item.id == firstParent.id) {
          found = item;
          break;
        }
      }
      if (found != null) {
        setModalState(() {
          selectedAtLevel[0] = found;
        });
        // Load children for subsequent levels recursively
        if (parentStack.length > 1 && found.childrenCount > 0) {
          _loadAndPreselectNextLevel(1, found.id, parentStack, spaceLevels, selectedAtLevel, loadingAtLevel, setModalState);
        }
      }
    }
  }

  void _loadAndPreselectNextLevel(
    int level,
    int parentId,
    List<Space> parentStack,
    List<List<_SpaceOptionItem>> spaceLevels,
    List<_SpaceOptionItem?> selectedAtLevel,
    List<bool> loadingAtLevel,
    StateSetter setModalState,
  ) {
    setModalState(() {
      spaceLevels.add([]);
      selectedAtLevel.add(null);
      loadingAtLevel.add(true);
    });
    sl<SpacesRepository>().getChildrenSpaces(parentId).then((children) {
      setModalState(() {
        spaceLevels[level] = children.map((s) => _SpaceOptionItem.fromSpace(s)).toList();
        loadingAtLevel[level] = false;
      });
      // Pre-select the matching item at this level
      if (level < parentStack.length) {
        final targetParent = parentStack[level];
        _SpaceOptionItem? found;
        for (final item in spaceLevels[level]) {
          if (item.id == targetParent.id) {
            found = item;
            break;
          }
        }
        if (found != null) {
          setModalState(() {
            selectedAtLevel[level] = found;
          });
          // Continue to next level if needed
          if (level + 1 < parentStack.length && found.childrenCount > 0) {
            _loadAndPreselectNextLevel(level + 1, found.id, parentStack, spaceLevels, selectedAtLevel, loadingAtLevel, setModalState);
          }
        }
      }
    }).catchError((_) {
      setModalState(() {
        loadingAtLevel[level] = false;
      });
    });
  }


// ═══════════════════════════════════════════════════════════════════
// REUSABLE WIDGETS
// ═══════════════════════════════════════════════════════════════════

// ─── TYPE CHIP ─────────────────────────────────────────────────
class _TypeChip extends StatelessWidget {
  final String label;
  final String? emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider.withValues(alpha: 0.5),
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(emoji!, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SPACE CARD ────────────────────────────────────────────────
class _SpaceCard extends StatelessWidget {
  final Space space;
  final void Function(Space) onTap;
  final void Function(Space) onEdit;
  final void Function(Space) onDelete;

  const _SpaceCard({
    required this.space,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(space),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 4, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Type icon
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _getTypeColor(space.type).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(space.typeEmoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      space.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontSize: 15,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      space.typeLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textHint,
                            fontSize: 12,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Flexible(
                          child: _InfoBadge(
                            icon: Icons.inventory_2_outlined,
                            label: '${space.assetsCount} bunuri',
                            color: const Color(0xFF667EEA),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: _InfoBadge(
                            icon: Icons.subdirectory_arrow_right_rounded,
                            label: '${space.childrenCount} sublocații',
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // 3-dot menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: AppColors.textHint, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                offset: const Offset(0, 40),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                        const SizedBox(width: 10),
                        const Text('Editează'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.error),
                        const SizedBox(width: 10),
                        Text('Șterge', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit(space);
                  } else if (value == 'delete') {
                    onDelete(space);
                  }
                },
              ),
              // Arrow for navigation
              const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(SpaceType type) {
    switch (type) {
      case SpaceType.home:
        return const Color(0xFF667EEA);
      case SpaceType.office:
        return const Color(0xFFF59E0B);
      case SpaceType.room:
        return const Color(0xFF10B981);
      case SpaceType.storage:
        return const Color(0xFF764BA2);
      case SpaceType.other:
        return const Color(0xFFEF4444);
    }
  }
}

// ─── INFO BADGE ────────────────────────────────────────────────
class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SPACE OPTION ITEM ───────────────────────────────────────────
class _SpaceOptionItem {
  final int id;
  final String name;
  final String type;
  final int childrenCount;

  const _SpaceOptionItem({
    required this.id,
    required this.name,
    required this.type,
    this.childrenCount = 0,
  });

  String get emoji {
    switch (type.toLowerCase()) {
      case 'home':
        return '🏠';
      case 'office':
        return '🏢';
      case 'room':
        return '🚪';
      case 'storage':
        return '📦';
      default:
        return '📍';
    }
  }

  static String _mapType(dynamic type) {
    if (type is int) {
      switch (type) {
        case 0:
          return 'home';
        case 1:
          return 'office';
        case 2:
          return 'room';
        case 3:
          return 'storage';
        default:
          return 'other';
      }
    }
    return type?.toString() ?? 'other';
  }

  factory _SpaceOptionItem.fromSpace(Space space) {
    return _SpaceOptionItem(
      id: space.id,
      name: space.name,
      type: space.type.name,
      childrenCount: space.childrenCount,
    );
  }

  factory _SpaceOptionItem.fromJson(Map<String, dynamic> json) {
    return _SpaceOptionItem(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      type: _mapType(json['type']),
      childrenCount: json['childrenCount'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is _SpaceOptionItem && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
