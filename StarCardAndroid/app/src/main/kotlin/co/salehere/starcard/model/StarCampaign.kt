package co.salehere.starcard.model

import co.salehere.starcard.theme.SHIcon

// MARK: - กิจกรรม Sale Here STAR (= StarCampaign.swift)
//
// ข้อมูลจำลองตามหน้าจอแอป Sale Here จริง (22 ก.ย. 2569) — ฝั่งแอปหลักดึงจาก `BrandCampaignDetails` (GraphQL)
// ไม่ผูกกับ `Profile`/`CardLibrary` เพราะเป็นของฝั่ง Sale Here ไม่ใช่ของ Star Card

/** คำถามเพิ่มของแบรนด์ในฟอร์มสมัคร (`UnboxRegister` questions) */
data class CampaignQuestion(
    val kind: Kind,
    val q: String,
    val options: List<String> = emptyList(),
) {
    enum class Kind { text, radio, checkbox, upload }

    val id: String get() = q
}

class StarCampaign(
    val id: String,
    /** เลข EP ที่แอปหลักโชว์หน้าชื่อ เช่น "EP.1585" */
    val episode: String,
    val title: String,
    val brand: String,
    /** drawable ของโลโก้แบรนด์ (วงกลม) — iOS เก็บชื่อ asset · ที่นี่เป็น `SHIcon.*` */
    val logo: Int,
    /** drawable ของรูปปก */
    val cover: Int,
    val dateRange: String,
    /** วิธีการร่วมกิจกรรม — ย่อหน้าเดียวแบบแอปหลัก */
    val howTo: String,
    /** เหลือเวลาลงทะเบียนอีกกี่วินาที นับจากตอนเปิดแอป · null = หมดเวลาแล้ว */
    val registerSecondsLeft: Double?,
    // ข้อมูลที่ฟอร์มสมัคร / หน้าตอบรับ / flow ใหม่ใช้ (= `CAMPAIGNS[].*` ของ unbox-mock)
    val reward: String = "",
    val quota: Int = 20,
    val registered: Int = 0,
    val socialChannels: List<StarSocial> = listOf(StarSocial.instagram),
    val contentTypes: List<String> = listOf("Photo"),
    val timeline: List<Pair<String, String>> = emptyList(),
    val questions: List<CampaignQuestion> = emptyList(),
    val acceptQuestions: List<CampaignQuestion> = emptyList(),
    /** ค่าตัว (บาท) · 0 = ได้ของอย่างเดียว */
    val fee: Int = 0,
) {
    /** เส้นตายลงทะเบียน (epoch millis) — ตรึงไว้ตอนโหลดข้อมูล นาฬิกาหน้ารายละเอียดนับถอยหลังจากค่านี้ */
    val deadline: Long? = registerSecondsLeft?.let { System.currentTimeMillis() + (it * 1000).toLong() }

    val isOpen: Boolean get() = registerSecondsLeft != null
    val headline: String get() = "$episode $title"

    override fun equals(other: Any?): Boolean = this === other || (other is StarCampaign && other.id == id)
    override fun hashCode(): Int = id.hashCode()

    companion object {
        val mock: List<StarCampaign> = listOf(
            StarCampaign(
                id = "1585", episode = "EP.1585",
                title = "WONDER ONE Music Festival 2027 รวมพลสายคอนเสิร์ต ท่ามกลางบรรยากาศธรรมชาติริมทะเลสาบ",
                brand = "WONDER ONE", logo = SHIcon.mockLogoWonder, cover = SHIcon.mockCoverWonder,
                dateRange = "21 ก.ย. 69 - 28 ก.ย. 69",
                howTo = "จัดเต็มความสนุกตั้งแต่เที่ยงวันยันเที่ยงคืนกับ 5 WONDERS ทั้งวิวธรรมชาติ ร้านเด็ดกว่า 30 ร้าน โซนถ่ายรูปสุดฮิป 🎡 และคอนเสิร์ตสุดอลังการจาก 7 ศิลปินฮอต JEFF SATUR, NONT TANONT, PiXXiE, MILLI, SLOT MACHINE, TIMETHAI และ RISA NARISA 🎶🔥 ปิดท้ายค่ำคืนด้วยงานไฟ Immersive Light สุดว้าว พร้อมที่จอดรถเพียบและห้องน้ำสะอาดติดสปีด 🚗 บัตร Early Bird มาพร้อมสิทธิพิเศษ จองก่อนได้ราคาดีกว่า แล้วเจอกันที่ริมทะเลสาบ!",
                registerSecondsLeft = (14 * 3600 + 59 * 60 + 48).toDouble(),
                reward = "บัตร Early Bird 2 ใบ + ชุด Merchandise", quota = 20, registered = 184,
                socialChannels = listOf(StarSocial.instagram, StarSocial.tiktok), contentTypes = listOf("Photo", "Short Video"),
                timeline = listOf("ลงทะเบียน" to "21 – 28 ก.ย. 69", "ประกาศผล" to "30 ก.ย. 69", "ตอบรับกิจกรรม" to "30 ก.ย. – 2 ต.ค. 69",
                    "จัดส่งสินค้า" to "3 ต.ค. 69", "ส่งดราฟต์รีวิว" to "5 – 12 ต.ค. 69", "ส่งลิงก์รีวิว" to "13 – 20 ต.ค. 69"),
                questions = listOf(
                    CampaignQuestion(kind = CampaignQuestion.Kind.text, q = "ทำไมคุณถึงอยากไปงานนี้? (สั้น ๆ)"),
                    CampaignQuestion(kind = CampaignQuestion.Kind.radio, q = "เคยไปเทศกาลดนตรีมาก่อนไหม", options = listOf("เคย", "ไม่เคย")),
                    CampaignQuestion(kind = CampaignQuestion.Kind.checkbox, q = "ศิลปินที่คุณตั้งใจไปดู", options = listOf("JEFF SATUR", "NONT TANONT", "PiXXiE", "MILLI", "SLOT MACHINE", "TIMETHAI", "RISA NARISA")),
                    CampaignQuestion(kind = CampaignQuestion.Kind.upload, q = "แนบตัวอย่างคอนเทนต์สายคอนเสิร์ตของคุณ"),
                ),
                acceptQuestions = listOf(CampaignQuestion(kind = CampaignQuestion.Kind.radio, q = "สะดวกไปงานวันไหน", options = listOf("เสาร์ 4 ต.ค.", "อาทิตย์ 5 ต.ค.", "ทั้งสองวัน"))),
                fee = 3000,
            ),
            StarCampaign(
                id = "1569", episode = "EP.1569",
                title = "Thymora ผลิตภัณฑ์สมุนไทยบำรุงผิว บอกลาปัญหาผิวและเส้นผม",
                brand = "Thymora", logo = SHIcon.mockLogoThymora, cover = SHIcon.mockCoverThymora,
                dateRange = "26 ส.ค. 69 - 30 ก.ย. 69",
                howTo = "รับผลิตภัณฑ์ Thymora ชุดบำรุงผิวและเส้นผมจากสมุนไพรไทย ทดลองใช้จริง 14 วัน แล้วรีวิวประสบการณ์ผ่านช่องทางของคุณ พร้อมแนบรูปก่อน-หลังใช้ และติดแฮชแท็ก #Thymora #SaleHereSTAR ในโพสต์ ทีมงานคัดเลือกรีวิวคุณภาพเพื่อรับของรางวัลเพิ่มเติม",
                registerSecondsLeft = (8 * 24 * 3600 + 3 * 3600 + 12 * 60 + 5).toDouble(),
                reward = "ชุดผลิตภัณฑ์ Thymora มูลค่า 1,890 บาท", quota = 50, registered = 412,
                socialChannels = listOf(StarSocial.instagram), contentTypes = listOf("Photo"),
                timeline = listOf("ลงทะเบียน" to "26 ส.ค. – 30 ก.ย. 69", "ประกาศผล" to "2 ต.ค. 69", "ตอบรับกิจกรรม" to "2 – 4 ต.ค. 69",
                    "จัดส่งสินค้า" to "6 ต.ค. 69", "ส่งดราฟต์รีวิว" to "20 – 27 ต.ค. 69", "ส่งลิงก์รีวิว" to "28 ต.ค. – 4 พ.ย. 69"),
                questions = listOf(CampaignQuestion(kind = CampaignQuestion.Kind.radio, q = "สภาพผิวของคุณ", options = listOf("ผิวมัน", "ผิวแห้ง", "ผิวผสม", "ผิวแพ้ง่าย"))),
            ),
            StarCampaign(
                id = "1571", episode = "EP.1571",
                title = "Terminal 21 เช็คอินคาเฟ่ลับ 5 ชั้น เก็บครบทุกมุมถ่ายรูป",
                brand = "Terminal 21", logo = SHIcon.photo3, cover = SHIcon.photo2,
                dateRange = "14 ก.ย. 69 - 20 ก.ย. 69",
                howTo = "เดินเก็บคาเฟ่ลับใน Terminal 21 ให้ครบ 5 ร้าน ถ่ายรูปกับมุมประจำชั้น แล้วโพสต์รีวิวแบบ carousel อย่างน้อย 5 รูป พร้อมพิกัดร้านและเมนูแนะนำ",
                registerSecondsLeft = null,
                reward = "Gift Voucher 1,000 บาท", quota = 30, socialChannels = listOf(StarSocial.instagram, StarSocial.lemon8), fee = 1500,
            ),
        )
    }
}
