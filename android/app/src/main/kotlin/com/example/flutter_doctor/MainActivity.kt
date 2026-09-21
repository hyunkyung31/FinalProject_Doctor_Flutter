package com.example.flutter_doctor

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // ============================================================
        // 병원 보안 정책
        // - 화면 캡처 방지
        // - 화면 녹화 시 의료정보 노출 방지
        // - 최근 앱 미리보기 보호
        // ============================================================

        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
    }
}
