import 'package:flutter/material.dart';

class CategoryDialog extends StatefulWidget {
  final String? initialName;
  final int? initialColor;
  final String? initialIcon;
  final Function(String name, int color, String? icon) onSave;

  const CategoryDialog({
    super.key,
    this.initialName,
    this.initialColor,
    this.initialIcon,
    required this.onSave,
  });

  @override
  State<CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<CategoryDialog> {
  late final TextEditingController _nameController;
  late int _selectedColor;
  late String? _selectedIcon;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _selectedColor = widget.initialColor ?? Colors.blue.toARGB32();
    _selectedIcon = widget.initialIcon;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  final List<Color> _colorOptions = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];

  final List<Map<String, dynamic>> _iconOptions = [
    {'name': 'work', 'icon': Icons.work},
    {'name': 'person', 'icon': Icons.person},
    {'name': 'lightbulb', 'icon': Icons.lightbulb},
    {'name': 'home', 'icon': Icons.home},
    {'name': 'favorite', 'icon': Icons.favorite},
    {'name': 'school', 'icon': Icons.school},
    {'name': 'shopping_cart', 'icon': Icons.shopping_cart},
    {'name': 'local_hospital', 'icon': Icons.local_hospital},
    {'name': 'directions_car', 'icon': Icons.directions_car},
    {'name': 'restaurant', 'icon': Icons.restaurant},
    {'name': 'folder', 'icon': Icons.folder},
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialName == null ? 'Add Category' : 'Edit Category'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a category name';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Color selection
              const Text('Color:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _colorOptions.map((color) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = color.toARGB32();
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedColor == color.toARGB32()
                              ? Colors.white
                              : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: _selectedColor == color.toARGB32()
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                  red: Colors.black.r, 
                                  green: Colors.black.g, 
                                  blue: Colors.black.b, 
                                  alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 16),
              
              // Icon selection
              const Text('Icon:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _iconOptions.map((option) {
                  final iconName = option['name'] as String;
                  final iconData = option['icon'] as IconData;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIcon = iconName;
                      });
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _selectedIcon == iconName
                            ? Color(_selectedColor)
                            : Theme.of(context).colorScheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedIcon == iconName
                              ? Colors.white
                              : Colors.grey.withValues(
                              red: Colors.grey.r, 
                              green: Colors.grey.g, 
                              blue: Colors.grey.b, 
                              alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        iconData,
                        color: _selectedIcon == iconName
                            ? Colors.white
                            : Colors.grey,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSave(
                _nameController.text.trim(),
                _selectedColor,
                _selectedIcon,
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}