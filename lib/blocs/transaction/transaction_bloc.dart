
import 'package:expense_manager_project/blocs/transaction/transaction_event.dart';
import 'package:expense_manager_project/blocs/transaction/transaction_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../services/storage_services.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  TransactionBloc() : super(TransactionInitial()) {
    on<LoadTransactions>(_onLoadTransactions);
    on<AddTransaction>(_onAddTransaction);
    on<UpdateTransaction>(_onUpdateTransaction);
    on<DeleteTransaction>(_onDeleteTransaction);
  }

  Future<void> _onLoadTransactions(
      LoadTransactions event,
      Emitter<TransactionState> emit,
      ) async {
    try {
      emit(const TransactionLoading());
      final transactions = await StorageService.getAllTransactionsAsync();
      emit(TransactionLoaded(transactions));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onAddTransaction(
      AddTransaction event,
      Emitter<TransactionState> emit,
      ) async {
    try {
      await StorageService.addTransaction(event.transaction);
      final transactions = await StorageService.getAllTransactionsAsync();
      emit(TransactionLoaded(transactions));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onUpdateTransaction(
      UpdateTransaction event,
      Emitter<TransactionState> emit,
      ) async {
    try {
      await StorageService.updateTransaction(event.transaction);
      final transactions = await StorageService.getAllTransactionsAsync();
      emit(TransactionLoaded(transactions));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onDeleteTransaction(
      DeleteTransaction event,
      Emitter<TransactionState> emit,
      ) async {
    try {
      await StorageService.deleteTransaction(event.id);
      final transactions = await StorageService.getAllTransactionsAsync();
      emit(TransactionLoaded(transactions));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }
 }
