import 'package:flutter/material.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';

// ============================================================
// STEP 1. Dashboard Common Section Card
// Dashboard 하단/중단 공통 카드
// ============================================================

class DashboardSectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;

  final String? actionLabel;
  final VoidCallback? onAction;

  final Widget child;

  const DashboardSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.appBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ======================================================
          // Header
          // ======================================================
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 36),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 7, 6),
              child: Row(
                children: [
                  // ================================================
                  // Title / Subtitle
                  // ================================================
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.appTextPrimary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.1,
                          ),
                        ),

                        if (subtitle != null &&
                            subtitle!.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: context.appTextSecondary,
                              fontSize: 8,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // ================================================
                  // Action
                  // ================================================
                  if (actionLabel != null)
                    TextButton(
                      onPressed: onAction,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 3,
                        ),
                        minimumSize: const Size(0, 26),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            actionLabel!,
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w600,
                              color: context.appTextSecondary,
                            ),
                          ),
                          const SizedBox(width: 1),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 13,
                            color: context.appTextSecondary,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ======================================================
          // Divider
          // ======================================================
          Divider(height: 1, thickness: 1, color: context.appBorder),

          // ======================================================
          // Content
          // ======================================================
          child,
        ],
      ),
    );
  }
}
