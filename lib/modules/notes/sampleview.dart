import 'package:flutter/material.dart';

abstract class SampleView extends StatefulWidget {
  const SampleView({Key? key}) : super(key: key);
}
 
abstract class SampleViewState<T extends SampleView> extends State<T> {} 