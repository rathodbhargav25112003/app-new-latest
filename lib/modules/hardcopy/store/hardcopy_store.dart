import 'package:mobx/mobx.dart';
import '../model/book_model.dart';
import '../../../api_service/api_service.dart';

part 'hardcopy_store.g.dart';

class HardcopyStore = _HardcopyStore with _$HardcopyStore;

abstract class _HardcopyStore with Store {
  final ApiService _apiService = ApiService();
  
  @observable
  bool isLoading = false;
  
  @observable
  ObservableList<BookModel> books = ObservableList<BookModel>();
  
  @observable
  String? error;
  
  @action
  Future<void> fetchAllBooks() async {
    isLoading = true;
    error = null;
    
    try {
      final booksList = await _apiService.getAllBooks();
      books.clear();
      books.addAll(booksList);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
    }
  }
  
  @action
  void clearBooks() {
    books.clear();
  }
} 