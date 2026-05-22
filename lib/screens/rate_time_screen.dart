import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../helpers/translations.dart';

class RateAndTimeScreen extends StatefulWidget {
  const RateAndTimeScreen({super.key});

  @override
  State<RateAndTimeScreen> createState() => _RateAndTimeScreenState();
}

class _RateAndTimeScreenState extends State<RateAndTimeScreen> {
  // Rates State
  final TextEditingController _rateController = TextEditingController();
  double _currentRate = 12.00;
  
  // Time State
  final TextEditingController _timeController = TextEditingController();
  int? _currentTime; // null means 'Not Set' or Infinite if we define 0 as infinite

  @override
  void dispose() {
    _rateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: theme.iconTheme.color),
        title: Text(
          context.tr.rateAndTime,
          style: TextStyle(color: theme.textTheme.titleLarge?.color, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // RATES SECTION
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.tr.rates,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.titleMedium?.color),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Current Rate Display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr.currentRate,
                            style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.tr.profileSubscriptionPrice,
                            style: TextStyle(fontSize: 12, color: theme.hintColor),
                          ),
                        ],
                      ),
                      Text(
                        "\$${_currentRate.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold, 
                          color: Color(0xFFDB2777), // Pink color
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Text(
                    context.tr.setNewRate,
                    style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color),
                  ),
                  const SizedBox(height: 8),
                  
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _rateController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          LengthLimitingTextInputFormatter(6),
                        ],
                        style: TextStyle(fontSize: 14, color: theme.textTheme.bodyLarge?.color),
                        decoration: InputDecoration(
                          hintText: context.tr.enterNewRateHint,
                          hintStyle: TextStyle(color: theme.hintColor, fontSize: 13),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                 final val = double.tryParse(_rateController.text);
                                 if (val != null) {
                                   if (val < 5 || val > 100) {
                                     ScaffoldMessenger.of(context).showSnackBar(
                                       SnackBar(content: Text(context.tr.rateMustBeBetween), backgroundColor: Colors.red),
                                     );
                                     return;
                                   }
                                   setState(() => _currentRate = val);
                                   _rateController.clear();
                                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr.rateUpdated)));
                                 }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFDB2777),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                              child: Text(context.tr.updateRate),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() => _currentRate = 0.0);
                                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr.rateSetToFree)));
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.textTheme.bodyLarge?.color,
                                backgroundColor: isDark ? const Color(0xFF334155) : Colors.grey[300], 
                                side: BorderSide.none,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text(context.tr.makeFree),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // TIME SECTION
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr.time,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.titleMedium?.color),
                  ),
                  const SizedBox(height: 24),

                  // Current Time Display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr.currentTime,
                              style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.tr.callCenterTimingDesc,
                              style: TextStyle(fontSize: 12, color: theme.hintColor, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        _currentTime == null ? context.tr.notSet : "${_currentTime}m",
                        style: const TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold, 
                          color: Color(0xFFDB2777),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Text(
                    context.tr.setNewTimeMinutes,
                    style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color),
                  ),
                  const SizedBox(height: 8),
                  
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _timeController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(2), // Max 99, logical limit 60 checked on button
                        ],
                        style: TextStyle(fontSize: 14, color: theme.textTheme.bodyLarge?.color),
                        decoration: InputDecoration(
                          hintText: context.tr.enterMinutesHint,
                          hintStyle: TextStyle(color: theme.hintColor, fontSize: 13),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                           final val = int.tryParse(_timeController.text);
                           if (val != null) {
                             if (val < 0 || val > 60) {
                               ScaffoldMessenger.of(context).showSnackBar(
                                 SnackBar(content: Text(context.tr.timeMustBeBetween), backgroundColor: Colors.red),
                               );
                               return;
                             }
                             setState(() => _currentTime = val);
                             _timeController.clear();
                             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr.timeUpdated)));
                           }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDB2777),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: Text(context.tr.updateTime),
                      ),
                      const SizedBox(height: 12),
                      // Disable Disconnection Button
                      OutlinedButton(
                        onPressed: () {
                           setState(() => _currentTime = 0); // Assuming 0 is infinite/disable
                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr.disconnectionDisabled)));
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.textTheme.bodyLarge?.color,
                          backgroundColor: isDark ? const Color(0xFF334155) : Colors.grey[300],
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(context.tr.disableDisconnection),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
