import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/space.dart';
import '../../domain/repositories/spaces_repository.dart';
import '../../data/models/space_model.dart';

// ─── Events ─────────────────────────────────────────────────────
abstract class SpacesEvent extends Equatable {
  const SpacesEvent();
  @override
  List<Object?> get props => [];
}

class LoadParentSpaces extends SpacesEvent {}

class LoadChildrenSpaces extends SpacesEvent {
  final Space parentSpace;
  const LoadChildrenSpaces(this.parentSpace);
  @override
  List<Object?> get props => [parentSpace];
}

class GoBackOneLevel extends SpacesEvent {}

class SearchSpaces extends SpacesEvent {
  final String query;
  const SearchSpaces(this.query);
  @override
  List<Object?> get props => [query];
}

class FilterByType extends SpacesEvent {
  final SpaceType? type;
  const FilterByType(this.type);
  @override
  List<Object?> get props => [type];
}

class CreateSpaceEvent extends SpacesEvent {
  final String name;
  final SpaceType type;
  final int? parentSpaceId;
  const CreateSpaceEvent({required this.name, required this.type, this.parentSpaceId});
  @override
  List<Object?> get props => [name, type, parentSpaceId];
}

class UpdateSpaceEvent extends SpacesEvent {
  final int spaceId;
  final String name;
  final SpaceType type;
  final int? parentSpaceId;
  final bool removeParent; // true = mutare ca locație principală (fără părinte)
  const UpdateSpaceEvent({
    required this.spaceId,
    required this.name,
    required this.type,
    this.parentSpaceId,
    this.removeParent = false,
  });
  @override
  List<Object?> get props => [spaceId, name, type, parentSpaceId, removeParent];
}

class DeleteSpaceEvent extends SpacesEvent {
  final int spaceId;
  const DeleteSpaceEvent(this.spaceId);
  @override
  List<Object?> get props => [spaceId];
}

// ─── States ─────────────────────────────────────────────────────
abstract class SpacesState extends Equatable {
  const SpacesState();
  @override
  List<Object?> get props => [];
}

class SpacesInitial extends SpacesState {}

class SpacesLoading extends SpacesState {}

class SpacesLoaded extends SpacesState {
  final List<Space> spaces;
  final List<Space> filteredSpaces;
  final Space? currentParent; // null = viewing root parents
  final List<Space> parentStack; // navigation history
  final String searchQuery;
  final SpaceType? selectedType;

  const SpacesLoaded({
    required this.spaces,
    required this.filteredSpaces,
    this.currentParent,
    this.parentStack = const [],
    this.searchQuery = '',
    this.selectedType,
  });

  bool get isViewingChildren => currentParent != null;

  @override
  List<Object?> get props => [spaces, filteredSpaces, currentParent, parentStack, searchQuery, selectedType];
}

class SpacesError extends SpacesState {
  final String message;
  const SpacesError(this.message);
  @override
  List<Object?> get props => [message];
}

class SpaceActionSuccess extends SpacesState {
  final String message;
  const SpaceActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── Bloc ───────────────────────────────────────────────────────
class SpacesBloc extends Bloc<SpacesEvent, SpacesState> {
  final SpacesRepository repository;

  SpacesBloc({required this.repository}) : super(SpacesInitial()) {
    on<LoadParentSpaces>(_onLoadParentSpaces);
    on<LoadChildrenSpaces>(_onLoadChildrenSpaces);
    on<GoBackOneLevel>(_onGoBackOneLevel);
    on<SearchSpaces>(_onSearchSpaces);
    on<FilterByType>(_onFilterByType);
    on<CreateSpaceEvent>(_onCreateSpace);
    on<UpdateSpaceEvent>(_onUpdateSpace);
    on<DeleteSpaceEvent>(_onDeleteSpace);
  }

  List<Space> _applyFilters({
    required List<Space> spaces,
    String searchQuery = '',
    SpaceType? selectedType,
  }) {
    var filtered = List<Space>.from(spaces);

    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((s) => s.name.toLowerCase().contains(query)).toList();
    }

    if (selectedType != null) {
      filtered = filtered.where((s) => s.type == selectedType).toList();
    }

    return filtered;
  }

  Future<void> _onLoadParentSpaces(LoadParentSpaces event, Emitter<SpacesState> emit) async {
    emit(SpacesLoading());
    try {
      final spaces = await repository.getParentSpaces();
      emit(SpacesLoaded(
        spaces: spaces,
        filteredSpaces: spaces,
        parentStack: const [],
      ));
    } catch (e) {
      emit(SpacesError('Nu s-au putut încărca locațiile: ${e.toString()}'));
    }
  }

  Future<void> _onLoadChildrenSpaces(LoadChildrenSpaces event, Emitter<SpacesState> emit) async {
    // Build the new stack by appending the parent we're entering
    final oldStack = state is SpacesLoaded ? (state as SpacesLoaded).parentStack : <Space>[];
    final newStack = [...oldStack, event.parentSpace];

    emit(SpacesLoading());
    try {
      final children = await repository.getChildrenSpaces(event.parentSpace.id);
      emit(SpacesLoaded(
        spaces: children,
        filteredSpaces: children,
        currentParent: event.parentSpace,
        parentStack: newStack,
      ));
    } catch (e) {
      emit(SpacesError('Nu s-au putut încărca sublocațiile: ${e.toString()}'));
    }
  }

  Future<void> _onGoBackOneLevel(GoBackOneLevel event, Emitter<SpacesState> emit) async {
    if (state is! SpacesLoaded) {
      add(LoadParentSpaces());
      return;
    }

    final s = state as SpacesLoaded;
    final stack = List<Space>.from(s.parentStack);

    if (stack.length <= 1) {
      // Go back to root parents
      add(LoadParentSpaces());
    } else {
      // Pop current, go to previous parent
      stack.removeLast();
      final previousParent = stack.last;

      emit(SpacesLoading());
      try {
        final children = await repository.getChildrenSpaces(previousParent.id);
        emit(SpacesLoaded(
          spaces: children,
          filteredSpaces: children,
          currentParent: previousParent,
          parentStack: stack,
        ));
      } catch (e) {
        emit(SpacesError('Nu s-au putut încărca sublocațiile: ${e.toString()}'));
      }
    }
  }

  void _onSearchSpaces(SearchSpaces event, Emitter<SpacesState> emit) {
    if (state is SpacesLoaded) {
      final s = state as SpacesLoaded;
      final filtered = _applyFilters(
        spaces: s.spaces,
        searchQuery: event.query,
        selectedType: s.selectedType,
      );
      emit(SpacesLoaded(
        spaces: s.spaces,
        filteredSpaces: filtered,
        currentParent: s.currentParent,
        parentStack: s.parentStack,
        searchQuery: event.query,
        selectedType: s.selectedType,
      ));
    }
  }

  void _onFilterByType(FilterByType event, Emitter<SpacesState> emit) {
    if (state is SpacesLoaded) {
      final s = state as SpacesLoaded;
      final filtered = _applyFilters(
        spaces: s.spaces,
        searchQuery: s.searchQuery,
        selectedType: event.type,
      );
      emit(SpacesLoaded(
        spaces: s.spaces,
        filteredSpaces: filtered,
        currentParent: s.currentParent,
        parentStack: s.parentStack,
        searchQuery: s.searchQuery,
        selectedType: event.type,
      ));
    }
  }

  Future<void> _onCreateSpace(CreateSpaceEvent event, Emitter<SpacesState> emit) async {
    try {
      final data = {
        'name': event.name,
        'type': SpaceModel.typeToInt(event.type),
        'parentSpaceId': event.parentSpaceId,
      };
      await repository.createSpace(data);
      // Reload the current view
      if (state is SpacesLoaded) {
        final s = state as SpacesLoaded;
        if (s.currentParent != null) {
          // Re-load children without pushing to stack again
          emit(SpacesLoading());
          final children = await repository.getChildrenSpaces(s.currentParent!.id);
          emit(SpacesLoaded(
            spaces: children,
            filteredSpaces: children,
            currentParent: s.currentParent,
            parentStack: s.parentStack,
          ));
        } else {
          add(LoadParentSpaces());
        }
      } else {
        add(LoadParentSpaces());
      }
    } catch (e) {
      emit(SpacesError('Nu s-a putut crea locația: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateSpace(UpdateSpaceEvent event, Emitter<SpacesState> emit) async {
    try {
      final data = <String, dynamic>{
        'name': event.name,
        'type': SpaceModel.typeToInt(event.type),
      };
      // Dacă se schimbă părintele sau se scoate părintele
      if (event.removeParent) {
        data['parentSpaceId'] = null;
      } else if (event.parentSpaceId != null) {
        data['parentSpaceId'] = event.parentSpaceId;
      }
      await repository.updateSpace(event.spaceId, data);
      // Reload the current view
      if (state is SpacesLoaded) {
        final s = state as SpacesLoaded;
        if (s.currentParent != null) {
          emit(SpacesLoading());
          final children = await repository.getChildrenSpaces(s.currentParent!.id);
          emit(SpacesLoaded(
            spaces: children,
            filteredSpaces: children,
            currentParent: s.currentParent,
            parentStack: s.parentStack,
          ));
        } else {
          add(LoadParentSpaces());
        }
      } else {
        add(LoadParentSpaces());
      }
    } catch (e) {
      emit(SpacesError('Nu s-a putut actualiza locația: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteSpace(DeleteSpaceEvent event, Emitter<SpacesState> emit) async {
    try {
      await repository.deleteSpace(event.spaceId);
      // Reload the current view
      if (state is SpacesLoaded) {
        final s = state as SpacesLoaded;
        if (s.currentParent != null) {
          emit(SpacesLoading());
          final children = await repository.getChildrenSpaces(s.currentParent!.id);
          emit(SpacesLoaded(
            spaces: children,
            filteredSpaces: children,
            currentParent: s.currentParent,
            parentStack: s.parentStack,
          ));
        } else {
          add(LoadParentSpaces());
        }
      } else {
        add(LoadParentSpaces());
      }
    } catch (e) {
      emit(SpacesError('Nu s-a putut șterge locația: ${e.toString()}'));
    }
  }
}
