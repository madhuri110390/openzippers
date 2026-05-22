import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../helpers/translations.dart';
import '../viewmodels/support_viewmodel.dart';

class ContactSupportDialog extends ConsumerStatefulWidget {
  const ContactSupportDialog({super.key});

  @override
  ConsumerState<ContactSupportDialog> createState() =>
      _ContactSupportDialogState();
}

class _ContactSupportDialogState
    extends ConsumerState<ContactSupportDialog> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String? _selectedCategory;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Define exact colors to match premium look
    final inputFillColor = isDark 
        ? const Color(0xFF1E293B) // Dark slate for dark mode
        : Colors.grey[100];
    
    final borderColor = isDark 
        ? Colors.white.withValues(alpha: 0.1) 
        : Colors.grey[300];


    final Map<String, String> categories = {
      context.tr.accountIssues: "account",
      context.tr.streamingProblems: "streaming",
      context.tr.billingQuestions: "billing",
      context.tr.technicalSupport: "technical",
      context.tr.categoryOther: "other",
    };

    return Dialog(
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.tr.contactSupport, // "Contact Support"
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.titleMedium?.color
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, size: 20, color: theme.hintColor),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Subject Field
                _buildLabel(context.tr.subject, isRequired: true, theme: theme),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _subjectController,
                  style: TextStyle(fontSize: 14, color: theme.textTheme.bodyLarge?.color),
                  decoration: _buildInputDecoration(
                    hintText: context.tr.enterSubject,
                    fillColor: inputFillColor,
                    borderColor: borderColor,
                    theme: theme,
                  ),
                ),
                const SizedBox(height: 16),

                // Category Dropdown
                _buildLabel(context.tr.category, isRequired: true, theme: theme),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,

                    selectedItemBuilder: (BuildContext context) {
                      return categories.keys.map<Widget>((String item) {
                        return Text(
                          item,
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        );
                      }).toList();
                    },

                    items: categories.keys.map((category) {
                      final isSelected = category == _selectedCategory;

                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: 14,
                            color: isSelected
                                ? const Color(0xFFDB2777)
                                : theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      );
                    }).toList(),
                  isExpanded: true,

                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },

                  icon: Icon(
                    Icons.unfold_more,
                    size: 20,
                    color: theme.hintColor,
                  ),

                  dropdownColor: theme.cardColor,

                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textTheme.bodyLarge?.color,
                  ),

                  decoration: _buildInputDecoration(
                    hintText: context.tr.selectCategory,
                    fillColor: inputFillColor,
                    borderColor: borderColor,
                    theme: theme,
                  ),

                  menuMaxHeight: 300,

                  borderRadius: BorderRadius.circular(12),
                ),
                const SizedBox(height: 16),

                // Message Field
                _buildLabel(context.tr.message, isRequired: true, theme: theme), // "Message"
                const SizedBox(height: 8),
                TextFormField(
                  controller: _messageController,
                  maxLines: 4,
                  style: TextStyle(fontSize: 14, color: theme.textTheme.bodyLarge?.color),
                  decoration: _buildInputDecoration(
                    hintText: context.tr.typeMessage,
                    fillColor: inputFillColor,
                    borderColor: borderColor,
                    theme: theme,
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        foregroundColor: theme.hintColor,
                      ),
                      child: Text(context.tr.cancel),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(

                      onPressed: () async {

                        if (_selectedCategory != null &&
                            _subjectController.text.isNotEmpty &&
                            _messageController.text.isNotEmpty) {

                          await ref
                              .read(supportViewModelProvider.notifier)
                              .submitSupport(
                            subject: _subjectController.text.trim(),

                            category: categories[_selectedCategory]!,

                            message: _messageController.text.trim(),

                            email: "guest@example.com",

                            name: "Guest User",
                          );

                          final state = ref.read(supportViewModelProvider);

                          if (state.successMessage != null && context.mounted) {

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(state.successMessage!),
                              ),
                            );

                            Navigator.pop(context);
                          }

                          if (state.errorMessage != null && context.mounted) {

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(state.errorMessage!),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }

                        } else {

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                context.tr.fillAllRequiredFields,
                              ),
                              backgroundColor: const Color(0xFFDB2777),
                            ),
                          );
                        }
                      },

                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDB2777),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),

                      child: ref.watch(supportViewModelProvider).isLoading
                          ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : Text(context.tr.sendMessage),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, {bool isRequired = false, required ThemeData theme}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: theme.textTheme.bodyLarge?.color,
        ),
        children: [
          if (isRequired)
            const TextSpan(
              text: '*',
              style: TextStyle(color: Color(0xFFDB2777)),
            ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required Color? fillColor,
    required Color? borderColor,
    required ThemeData theme,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(fontSize: 14, color: theme.hintColor.withValues(alpha: 0.7)),
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderColor ?? Colors.transparent),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderColor ?? Colors.transparent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFDB2777)),
      ),
    );
  }
}
