import 'package:flutter/material.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';

import '../../../../core/theme/app_theme.dart';

class PatientResponsiveLayout extends StatefulWidget {
  final Widget patientList;
  final Widget patientDetail;

  final bool showCompactDetail;
  final VoidCallback onBackToList;

  final double breakpoint;

  const PatientResponsiveLayout({
    super.key,
    required this.patientList,
    required this.patientDetail,
    required this.showCompactDetail,
    required this.onBackToList,
    this.breakpoint = 900,
  });

  @override
  State<PatientResponsiveLayout> createState() =>
      _PatientResponsiveLayoutState();
}

class _PatientResponsiveLayoutState extends State<PatientResponsiveLayout> {
  bool _isPatientListCollapsed = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < widget.breakpoint;

        if (!isCompact) {
          const handleWidth = 28.0;
          const handleGap = 6.0;

          final availableWidth =
              constraints.maxWidth - handleWidth - (handleGap * 2);

          final patientListWidth = availableWidth * 0.30;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Offstage(
                offstage: _isPatientListCollapsed,
                child: SizedBox(
                  width: patientListWidth,
                  child: widget.patientList,
                ),
              ),

              if (!_isPatientListCollapsed) const SizedBox(width: handleGap),

              _PatientListToggleButton(
                collapsed: _isPatientListCollapsed,
                onTap: () {
                  setState(() {
                    _isPatientListCollapsed = !_isPatientListCollapsed;
                  });
                },
              ),

              const SizedBox(width: handleGap),

              Expanded(child: widget.patientDetail),
            ],
          );
        }

        return IndexedStack(
          index: widget.showCompactDetail ? 1 : 0,
          children: [
            widget.patientList,
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CompactBackBar(onBackToList: widget.onBackToList),
                const SizedBox(height: 6),
                Expanded(child: widget.patientDetail),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _PatientListToggleButton extends StatelessWidget {
  final bool collapsed;
  final VoidCallback onTap;

  const _PatientListToggleButton({
    required this.collapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Align(
        alignment: Alignment.topCenter,
        child: Tooltip(
          message: collapsed ? '환자 목록 펼치기' : '환자 목록 접기',
          child: Container(
            width: 28,
            height: 36,
            decoration: BoxDecoration(
              color: context.appSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.appBorder),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(8),
                child: Icon(
                  collapsed
                      ? Icons.chevron_right_rounded
                      : Icons.chevron_left_rounded,
                  size: 18,
                  color: AppColors.navy,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactBackBar extends StatelessWidget {
  final VoidCallback onBackToList;

  const _CompactBackBar({required this.onBackToList});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onBackToList,
            borderRadius: BorderRadius.circular(8),
            child: const SizedBox(
              width: 110,
              height: 36,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_back_rounded,
                      size: 16,
                      color: AppColors.navy,
                    ),
                    SizedBox(width: 7),
                    Text(
                      '환자 목록',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
