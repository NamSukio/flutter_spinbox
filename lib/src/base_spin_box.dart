// MIT License
//
// Copyright (c) 2020 J-P Nurmi <jpnurmi@gmail.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinbox_fork/src/number_formatter.dart';
import 'package:meta/meta.dart';

// ignore_for_file: public_member_api_docs

abstract class BaseSpinBox extends StatefulWidget {
  const BaseSpinBox({Key? key}) : super(key: key);

  double get min;
  double get max;
  double get step;
  double get value;
  int get numOfDecimals;
  ValueChanged<double?>? get onChanged;
}

abstract class BaseSpinBoxState<T extends BaseSpinBox> extends State<T> {
  double? _value;
  FocusNode? _focusNode;
  TextEditingController? _controller;

  double? get value => _value;
  bool get hasFocus => _focusNode?.hasFocus ?? false;
  FocusNode? get focusNode => _focusNode;
  TextEditingController? get controller => _controller;

  static double? _parseValue(String text) {
    if (text.isEmpty) return 0;
    return double.tryParse(text.replaceAll(',', ''));
  }

  String _formatText(dynamic? number) {
    return formatCurrencyForeign(
      number,
      decimals: widget.numOfDecimals,
      numOfInteger: widget.max.toInt().toString().length,
    );
  }

  @override
  void initState() {
    super.initState();
    _value = widget.value;
    _controller = TextEditingController(
        text:
            _formatText(_value!.toInt() == _value ? _value!.toInt() : _value));
    _controller!.addListener(_updateValue);
    _focusNode = FocusNode(onKey: (node, event) => _handleKey(event));
    _focusNode!.addListener(() => setState(_selectAll));
    _focusNode!.addListener(() {
      if (hasFocus) return;
      fixupValue(controller!.text);
    });
  }

  @override
  void dispose() {
    _focusNode?.dispose();
    _focusNode = null;
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  bool _handleKey(RawKeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      return event is RawKeyUpEvent || setValue(value! + widget.step);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      return event is RawKeyUpEvent || setValue(value! - widget.step);
    }
    return false;
  }

  void _updateValue() {
    final v = _parseValue(_controller!.text);
    if (v == _value) return;
    setState(() => _value = v);
    widget.onChanged?.call(v);
  }

  bool setValue(double v) {
    final newValue = v.clamp(widget.min, widget.max).toDouble();
    if (newValue == value) return false;
    final text =
        _formatText(newValue.toInt() == newValue ? newValue.toInt() : newValue);
    final selection = _controller!.selection;
    final oldOffset = value!.isNegative ? 1 : 0;
    final newOffset = _parseValue(text)!.isNegative ? 1 : 0;
    setState(() {
      _controller!.value = _controller!.value.copyWith(
        text: text,
        selection: selection.copyWith(
          baseOffset: selection.baseOffset - oldOffset + newOffset,
          extentOffset: selection.extentOffset - oldOffset + newOffset,
        ),
      );
    });
    return true;
  }

  @protected
  void fixupValue(String value) {
    final v = _parseValue(value)!;
    _controller!.text = _formatText(v.toInt() == v ? v.toInt() : v);
  }

  void _selectAll() {
    if (!_focusNode!.hasFocus) return;
    _controller!.selection = _controller!.selection
        .copyWith(baseOffset: 0, extentOffset: _controller!.text.length);
  }
}
