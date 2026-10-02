//
//  StarCardApp.swift
//  StarCard
//
//  Created by salehere on 22/8/2569 BE.
//

import SwiftUI

@main
struct StarCardApp: App {
    init() {
        // ก่อนสโตร์ใดอ่านดิสก์ — โหมดลองทำต้องสำรอง/คืนข้อมูลเดิมให้เสร็จก่อน (ดู `LabMode`)
        LabMode.bootstrap()
        SHFont.register()
        // การ์ดต้องตรงกับ Star Profile ตั้งแต่เฟรมแรก — รวมล้างข้อมูลตัวอย่างที่ build ก่อนหน้าเคยเติมไว้
        Profile.me.sync(from: StarFlow.shared)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
