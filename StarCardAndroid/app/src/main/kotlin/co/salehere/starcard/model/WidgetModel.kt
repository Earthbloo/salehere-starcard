package co.salehere.starcard.model

import androidx.compose.runtime.compositionLocalOf
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import co.salehere.starcard.components.EntranceStyle
import co.salehere.starcard.layout.PageLayout
import co.salehere.starcard.theme.WidgetTextStyle
import java.util.UUID
import kotlin.math.roundToInt

// MARK: - Tier

/**
 * ชั้นของ widget — กำหนดว่าผู้ใช้แต่งได้แค่ไหน
 * กฎหลักของโปรดักต์: ชั้น `verified` แต่งหน้าตาไม่ได้ เพราะมันคือหลักฐาน ไม่ใช่งานศิลปะ
 */
enum class WidgetTier {
    /** แพลตฟอร์มออกให้ · ลากย้ายได้ · ขนาด/หน้าตาล็อก */
    verified,
    /** มาจาก OAuth · เลือก variant + ขนาดได้ · ตัวเลขแก้ไม่ได้ */
    connected,
    /** ตัวตน · อิสระเต็มที่ */
    personal;

    val label: String
        get() = when (this) {
            verified -> "หลักฐาน"
            connected -> "เชื่อมต่อ"
            personal -> "ตัวตน"
        }
    val icon: String
        get() = when (this) {
            verified -> "checkmark.seal.fill"
            connected -> "link"
            personal -> "paintbrush.fill"
        }
}

/**
 * หมวดใน gallery — แบ่งตาม "คำถามที่แบรนด์ถาม" เหลือสามคำถามใหญ่
 * ฉันเป็นใคร · จ้างฉันยังไง · ฉันทำอะไรมาแล้ว
 */
enum class WidgetGroup {
    about, booking, work;

    val raw: String get() = name
    val id: String get() = raw

    val label: String
        get() = when (this) {
            about -> "เกี่ยวกับฉัน"
            booking -> "รับงาน"
            work -> "ผลงาน"
        }
    val icon: String
        get() = when (this) {
            about -> "person.crop.square"
            booking -> "briefcase.fill"
            work -> "photo.on.rectangle.angled"
        }

    companion object {
        fun from(raw: String?): WidgetGroup? = entries.firstOrNull { it.raw == raw }
    }
}

/**
 * ตระกูลของ widget — กลุ่มที่ "สลับหน้าตากันได้" เพราะเล่าเรื่องเดียวกัน
 *
 * กติกาข้อบังคับของทุกตระกูล: **ทุกแบบต้องแสดงฟิลด์ชุดเดียวกัน**
 * ถ้าแบบหนึ่งโชว์สองบรรทัดแต่อีกแบบโชว์บรรทัดเดียว การกด "แบบอื่น" จะกลายเป็นการ
 * *เพิ่ม/ลดข้อมูล* แทนที่จะเป็นการ *เปลี่ยนหน้าตา*
 */
enum class WidgetFamily {
    // ลำดับนี้คือลำดับที่โผล่ในตู้ — ของหลักมาก่อน ถ้อยคำปิดท้ายทั้งสองหมวด
    // `text` อยู่ต่อจาก `intro` ไม่ใช่ท้ายสุด · `seal` ต่อจาก `hero` ทันที
    hero, seal, intro, text, followers, audience, tags, brand, verified,
    photo, showcase, words, rate, contact,
    /** สัดส่วนร่างกาย — สายแฟชั่น/บิวตี้/นายแบบ (พิมพ์เองทุกช่อง เว้นว่างได้) */
    body;

    val raw: String get() = name
    val id: String get() = raw

    val label: String
        get() = when (this) {
            hero -> "โปรไฟล์"
            body -> "สัดส่วน"
            intro -> "แนะนำตัว"
            brand -> "แบรนด์"
            verified -> "ผลงานยืนยัน"
            seal -> "ตรารับรอง"
            followers -> "ผู้ติดตาม"
            photo -> "รูปผลงาน"
            showcase -> "แผ่นโชว์ผลงาน"
            words -> "ถ้อยคำ"
            text -> "ข้อความ"
            tags -> "หมวดหมู่"
            audience -> "ผู้ชม"
            rate -> "เรตราคา"
            contact -> "ติดต่อ"
        }

    /**
     * หัวข้อใน Star Profile ที่ตระกูลนี้ดึงข้อมูลมาโชว์ — null = ไม่ผูก (ของตกแต่ง / ผลงานจาก Portfolio / ข้อมูลบัญชี)
     * ผูกแล้วได้สองอย่าง: ยังไม่กรอกหัวข้อนั้น = ช่องในตู้พาไปกรอกข้อนั้นข้อเดียว ·
     * กรอกครบ = ทุกแบบในตระกูลใช้ได้ทันที (ผู้ใช้ 23 ก.ย. 2569)
     */
    val topic: StarTopic?
        get() = when (this) {
            hero, tags -> StarTopic.Data(StarDataKey.categories)
            followers -> StarTopic.Data(StarDataKey.socials)
            intro, words -> StarTopic.Data(StarDataKey.about)
            rate -> StarTopic.Data(StarDataKey.rate)
            audience -> StarTopic.Data(StarDataKey.insight)
            seal -> StarTopic.Verify
            // แบรนด์ + ผลงานยืนยัน = หลักฐานจากระบบ ปลดล็อกเมื่อทำงานผ่าน Sale Here จบแล้วอย่างน้อย 1 งาน (ผู้ใช้ 23 ก.ย. 2569)
            brand, verified -> StarTopic.Work
            text, body, photo, showcase, contact -> null
        }

    val trayGroup: TrayGroup
        get() = when (this) {
            hero -> TrayGroup.profile
            followers -> TrayGroup.channels
            tags -> TrayGroup.niche
            intro, words -> TrayGroup.intro
            rate -> TrayGroup.rate
            audience -> TrayGroup.audience
            seal -> TrayGroup.verify
            photo, showcase, brand, verified -> TrayGroup.work
            contact -> TrayGroup.contact
            text, body -> TrayGroup.decor
        }

    companion object {
        fun from(raw: String?): WidgetFamily? = entries.firstOrNull { it.raw == raw }
    }
}

/**
 * หมวดในตู้ widget = หัวข้อของ Star Profile (ผู้ใช้ 23 ก.ย. 2569: "cat ต้องตรงกับ Star Profile แล้ว scroll เอาแทน")
 * ชิปเลื่อนแนวนอนแทนแท็บสามแท็บ · ลำดับ = ลำดับที่การ์ดเล่าเรื่อง
 * สามหมวดท้ายไม่ผูกกับ Star Profile: ผลงาน (จาก Portfolio) · ติดต่อ (จากบัญชี) · ข้อความ (ของตกแต่ง)
 */
enum class TrayGroup {
    profile, channels, niche, intro, rate, audience, verify, work, contact, decor;

    val raw: String get() = name
    val id: String get() = raw

    val label: String
        get() = when (this) {
            profile -> "โปรไฟล์"
            channels -> "ช่องทาง"
            niche -> "สายที่ใช่"
            intro -> "แนะนำตัว"
            rate -> "เรทรับงาน"
            audience -> "ข้อมูลผู้ติดตาม"
            verify -> "ยืนยันตัวตน"
            work -> "ผลงาน"
            contact -> "ติดต่อ"
            decor -> "ข้อความ"
        }

    val topic: StarTopic?
        get() = when (this) {
            profile, niche -> StarTopic.Data(StarDataKey.categories)
            channels -> StarTopic.Data(StarDataKey.socials)
            intro -> StarTopic.Data(StarDataKey.about)
            rate -> StarTopic.Data(StarDataKey.rate)
            audience -> StarTopic.Data(StarDataKey.insight)
            verify -> StarTopic.Verify
            work, contact, decor -> null
        }

    companion object {
        fun from(raw: String?): TrayGroup? = entries.firstOrNull { it.raw == raw }
    }
}

/** หัวข้อ Star Profile ที่ widget ผูกอยู่ — ช่องข้อมูล หรือ ยืนยันตัวตน */
sealed class StarTopic {
    data class Data(val key: StarDataKey) : StarTopic()
    data object Verify : StarTopic()
    /** เคยทำงานผ่าน Sale Here จบแล้ว — กรอกเองไม่ได้ ต้องไปรับงาน */
    data object Work : StarTopic()

    val label: String
        get() = when (this) {
            is Data -> key.label
            Verify -> "ยืนยันตัวตน"
            Work -> "ผลงานกับ Sale Here"
        }

    /** คำบนปุ่มของใบที่ยังว่าง */
    val action: String
        get() = when (this) {
            is Data -> "กรอก${key.label}"
            Verify -> "ยืนยันตัวตน"
            Work -> "ทำงานกับ Sale Here ก่อน"
        }

    /** คำบอกที่หัวหมวด */
    val missingLine: String
        get() = when (this) {
            is Data -> "ยังไม่มี${key.label}"
            Verify -> "ยังไม่ได้ยืนยันตัวตน"
            Work -> "ปลดล็อกเมื่อทำงานผ่าน Sale Here จบ 1 งาน"
        }

    /** ปลดล็อกด้วยการกรอกได้ไหม (ผลงานกับ Sale Here ต้องไปรับงาน ไม่มี wizard) */
    val fillable: Boolean get() = this != Work

    /** ขั้นของ wizard ที่ต้องเปิดเพื่อกรอกหัวข้อนี้ */
    val step: WizStep
        get() = when (this) {
            is Data -> WizStep.from(key.raw) ?: WizStep.about
            Verify -> WizStep.kyc
            Work -> WizStep.about
        }

    /** กรอกหัวข้อนี้แล้วหรือยัง (ดูจาก state ของ flow ใหม่ — ตัวเดียวกับ Star Profile) */
    val filled: Boolean
        get() = when (this) {
            is Data -> StarFlow.shared.has(key)
            Verify -> StarFlow.shared.verify != VerifyStatus.none
            Work -> StarFlow.shared.reviewed
        }
}

// MARK: - วัสดุของสำรับสติกเกอร์

/**
 * กระดาษเทป หรือ กระจกชมพู — เดิมคำนวณจากมุมของธีม ตอนนี้เป็นส่วนหนึ่งของชนิด
 * (ดู `WidgetKind.popSkin` · หน้าตาของแต่ละวัสดุอยู่ใน `PopWidgets`)
 */
enum class PopSkin {
    paper, glass;

    val raw: String get() = name

    val label: String
        get() = when (this) {
            paper -> "กระดาษเทป"
            glass -> "กระจกชมพู"
        }

    companion object {
        fun from(raw: String?): PopSkin? = entries.firstOrNull { it.raw == raw }
    }
}

// MARK: - Kind

enum class WidgetKind {
    // โปรไฟล์
    artPortrait, artTypeOver, artPolaroid, heroMinimal, heroAura,
    // โปรไฟล์ — ตระกูลคัตเอาต์ (ดู `CutoutWidgets`)
    // สองตัวนี้อ่าน **ช่องอัลฟา** ของรูป รูปที่ผู้ใช้ลบพื้นหลังมาแล้วจะไม่ถูกขังในสี่เหลี่ยม
    artNameBehind, artBreakout,
    // โปรไฟล์ — โปสเตอร์พอร์ต: ตัวเดียวในตระกูลคัตเอาต์ที่ **เป็นแผ่นพิมพ์** ไม่ใช่เวทีมืด
    artPortfolio,
    // เกี่ยวกับฉัน
    aboutText, interestTags,
    // หลักฐาน — โลโก้แบรนด์
    proofBrandGrid, proofBrandRail, proofBrandCoins,
    // หลักฐาน — ผลงานยืนยัน สองหน้าตาของเรื่องเดียวกัน · **รูปคือตัวนำ** ไม่ใช่ตัวประกอบ
    proofWork, proofTicket,
    // หลักฐาน — ตรารับรอง (ดู `VerifiedSealWidget`) ใบเดียวที่ **เนื้อหาคือคำรับรอง**
    proofSeal,
    // ผู้ติดตาม
    statGiant, socialChips, socialTiles, statWrapped,
    // ผู้ติดตาม — โปสเตอร์แถวสถิติ (ดู `StatPosterWidget`) ใบเดียวที่ **ไม่ใช่ป้ายข้อมูล**
    statPoster,
    // ผลงาน
    artFilmstrip, artDuo, artPair, workFeatured, workReel, artPhotobooth,
    // ผลงาน — สำรับ "กองรูป" แปดสถานการณ์ (ดู `GalleryWidgets`) เรียงตามความหนาแน่นของรูป
    galleryStack, galleryCarousel, galleryMasonry, galleryMosaic,
    galleryPost, galleryStory, galleryFilm, galleryTape,
    // ผลงาน — แผ่นโชว์คลิป (ดู `ShowcaseWidgets`) ตัวเดียวในตู้ที่เป็น **แผ่นพรีเซนต์ทั้งแผ่น**
    reelShowcase,
    // เนื้อหา
    typeMarquee, typeQuote, nicheTags, stickerTags,
    // สายงาน — โปสเตอร์ที่เอาแท็กไปล้อมตัวคน (ดู `NichePosterWidget`) เนื้อหาคือแท็ก ไม่ใช่ชื่อ
    nichePoster,
    // ข้อความล้วน — ตัวเดียวในตู้ที่ *ไม่มีเนื้อหาของตัวเอง* นอกจากที่เจ้าของการ์ดพิมพ์ลงไป
    textBlock,
    // เรตราคา — สเปกหมวด 5.1 · หกหน้าตาของราคาชุดเดียวกัน
    rateTags, rateNeon,
    // ช่องทางติดต่อ — สเปก 1.3 · สี่แบบมินิมอล · โปสเตอร์ติดต่อ (ใบเดียวในตระกูลที่ **เป็นภาพ**)
    contactCard, contactQR,
    contactBar, contactStack, contactLine, contactChips,
    contactPoster,
    // ประชากรผู้ติดตาม — สเปก 2.3
    audienceLine, audienceSplit, audienceAge, audienceMap,
    // ผู้ชม — โปสเตอร์อินไซต์ (ดู `InsightPosterWidget`) วาด **ทุกชุดพร้อมกัน** บนแผ่นเดียว
    audiencePoster,
    // สำรับ "แผ่นสติกเกอร์" — **แปดหน้าที่ × สองวัสดุ = สิบหกตัว** (ดู `PopWidgets`)
    // วัสดุเป็นของ *ชนิด* (ดู `popSkin`) ไม่ใช่ของธีม — ตู้จึงหยิบทั้งสองวัสดุได้โดยไม่ต้องสลับธีม
    popHeroPaper, popHeroGlass,
    popVideoPaper, popVideoGlass,
    popStatsGlass,
    popWorkPaper, popWorkGlass,
    popRatePaper, popRateGlass,
    popNichePaper, popNicheGlass,
    popBodyPaper, popBodyGlass,
    popContactPaper, popContactGlass,
    // สำรับบรรณาธิการ — แปลงตรงจากแผ่นตัวอย่างแปดใบ (ดู `EditorialWidgets`)
    // ทั้งสำรับมี **ตัวอักษรเป็นผัง** ข้อความของมันจึงเก็บต่อชิ้น (`ProfileField.note` + `index`)
    wallPolaroid, wallMemory, zineCover,
    aboutEditorial, aboutBehind,
    sayClarity, sayPitch, flowCards;

    val raw: String get() = name
    val id: String get() = raw

    /**
     * หน้าที่ของกล่องในสำรับสติกเกอร์ — "กล่องนี้เล่าเรื่องอะไร" (วัสดุอยู่ที่ `popSkin`)
     * ชื่อ ไอคอน และขนาด เป็นของหน้าที่ ไม่ใช่ของวัสดุ — ฝาแฝดสองใบจึงต่างกันแค่คำต่อท้ายชื่อ
     */
    enum class PopRole {
        hero, video, stats, work, rate, niche, body, contact;

        val title: String
            get() = when (this) {
                hero -> "ป้ายชื่อ"
                video -> "หน้าต่างวิดีโอ"
                stats -> "ผู้ติดตามสามช่อง"
                work -> "ผลงานสามใบ"
                rate -> "ใบเรตราคา"
                niche -> "สายงานแบบลิสต์"
                body -> "สัดส่วน"
                contact -> "ช่องทางติดต่อสามแถว"
            }

        val symbol: String
            get() = when (this) {
                hero -> "person.crop.square.fill"
                video -> "play.rectangle.fill"
                stats -> "flag.fill"
                work -> "rosette"
                rate -> "tag.fill"
                niche -> "list.bullet.clipboard.fill"
                body -> "figure.stand"
                contact -> "person.fill"
            }

        /** ผังในเทมเพลต `storyPop*` (แปลงจาก 810×1080 → กว้าง 504) */
        val defaultSize: Size
            get() = when (this) {
                hero -> Size(277f, 250f)
                video -> Size(215f, 202f)
                stats -> Size(504f, 172f)
                work -> Size(350f, 172f)
                rate -> Size(142f, 182f)
                niche -> Size(160f, 214f)
                body, contact -> Size(160f, 214f)
            }
    }

    /** หน้าที่ + วัสดุ ในสวิตช์เดียว — ที่เหลือทั้งไฟล์อ่านต่อจากตรงนี้ จึงไม่มี switch ไหนต้องไล่สิบหกตัวอีก */
    private val popParts: Pair<PopRole, PopSkin>?
        get() = when (this) {
            popHeroPaper -> PopRole.hero to PopSkin.paper
            popHeroGlass -> PopRole.hero to PopSkin.glass
            popVideoPaper -> PopRole.video to PopSkin.paper
            popVideoGlass -> PopRole.video to PopSkin.glass
            popStatsGlass -> PopRole.stats to PopSkin.glass
            popWorkPaper -> PopRole.work to PopSkin.paper
            popWorkGlass -> PopRole.work to PopSkin.glass
            popRatePaper -> PopRole.rate to PopSkin.paper
            popRateGlass -> PopRole.rate to PopSkin.glass
            popNichePaper -> PopRole.niche to PopSkin.paper
            popNicheGlass -> PopRole.niche to PopSkin.glass
            popBodyPaper -> PopRole.body to PopSkin.paper
            popBodyGlass -> PopRole.body to PopSkin.glass
            popContactPaper -> PopRole.contact to PopSkin.paper
            popContactGlass -> PopRole.contact to PopSkin.glass
            else -> null
        }

    val popRole: PopRole? get() = popParts?.first
    /** วัสดุของแผ่น — `null` แปลว่าไม่ใช่สำรับสติกเกอร์ */
    val popSkin: PopSkin? get() = popParts?.second

    /** สำรับแผ่นสติกเกอร์ — เช็คทีเดียวแทนไล่ทั้งสำรับทุก switch */
    val isPop: Boolean get() = popParts != null

    /** ฝาแฝดอีกวัสดุหนึ่งของกล่องเดียวกัน — ใช้ตอนสลับวัสดุทั้งการ์ด */
    val popTwin: WidgetKind?
        get() {
            val p = popParts ?: return null
            val other = if (p.second == PopSkin.paper) PopSkin.glass else PopSkin.paper
            return WidgetKind.entries.firstOrNull { it.popRole == p.first && it.popSkin == other }
        }

    /**
     * หมวดใน gallery
     * ตัวเลขผู้ติดตามอยู่ "เกี่ยวกับฉัน" เพราะมันคือขนาดของตัวเรา ไม่ใช่งานที่เคยทำ
     * ส่วนแถบวิ่งโชว์ชื่อแบรนด์ที่ร่วมงาน จึงเป็นผลงาน ไม่ใช่ของตกแต่ง
     */
    val group: WidgetGroup
        get() = when (this) {
            artPortrait, artTypeOver, artPolaroid, heroMinimal, heroAura,
            artNameBehind, artBreakout, artPortfolio,
            aboutText, statGiant, socialChips, socialTiles, statWrapped, statPoster,
            nicheTags, stickerTags, interestTags, nichePoster, typeQuote, textBlock,
            // ประชากรผู้ติดตามคือ "หน้าตาของคนที่ตามเรา" จึงอยู่หมวดเดียวกับยอดฟอลโลว์
            audienceLine, audienceSplit, audienceAge, audienceMap, audiencePoster,
            // ตรารับรองตอบคำถาม "เชื่อคนนี้ได้แค่ไหน" — เรื่องของตัวคน ไม่ใช่ของงานชิ้นใด
            proofSeal,
            // สำรับสติกเกอร์ — สองวัสดุอยู่หมวดเดียวกันเสมอ (หมวดมาจากหน้าที่ ไม่ใช่วัสดุ)
            popHeroPaper, popHeroGlass, popStatsGlass,
            popNichePaper, popNicheGlass, popBodyPaper, popBodyGlass,
            // สำรับบรรณาธิการ — หน้าแนะนำตัว · ประโยคเดี่ยว · การ์ดขั้นตอน คือ "ฉันเป็นใคร"
            aboutEditorial, aboutBehind, sayClarity, sayPitch, flowCards ->
                WidgetGroup.about
            // ทุกอย่างที่ตอบคำถาม "จ้างยังไง เท่าไหร่ ติดต่อใคร"
            rateTags, rateNeon,
            contactCard, contactQR,
            contactBar, contactStack, contactLine, contactChips, contactPoster,
            popRatePaper, popRateGlass, popContactPaper, popContactGlass ->
                WidgetGroup.booking
            proofBrandGrid, proofBrandRail, proofBrandCoins,
            proofWork, proofTicket, typeMarquee,
            artFilmstrip, artDuo, artPair, workFeatured, workReel, artPhotobooth,
            galleryStack, galleryCarousel, galleryMasonry, galleryMosaic,
            galleryPost, galleryStory, galleryFilm, galleryTape, reelShowcase,
            popVideoPaper, popVideoGlass, popWorkPaper, popWorkGlass,
            // กองรูปแบบบรรณาธิการ — ทั้งสามใบมีรูปเป็นเนื้อหาหลัก
            wallPolaroid, wallMemory, zineCover ->
                WidgetGroup.work
        }

    /** ตระกูล — ใช้หา "แบบอื่น" ที่สลับกันแล้วยังเล่าเรื่องเดิม */
    val family: WidgetFamily
        get() = when (this) {
            // ฝาแฝดสองวัสดุอยู่ตระกูลเดียวกัน — ปุ่ม "เปลี่ยนแบบ" จึงสลับกระดาษ↔กระจกได้ในตัว
            artPortrait, artTypeOver, artPolaroid, heroMinimal, heroAura,
            // อยู่ตระกูลเดียวกับหน้าโปรไฟล์ที่เหลือ — กด "เปลี่ยนแบบ" จากปกนิตยสารแล้วเจอได้
            artNameBehind, artBreakout, artPortfolio,
            popHeroPaper, popHeroGlass -> WidgetFamily.hero
            aboutText, aboutEditorial, aboutBehind -> WidgetFamily.intro
            popStatsGlass -> WidgetFamily.followers
            popVideoPaper, popVideoGlass, popWorkPaper, popWorkGlass -> WidgetFamily.photo
            popRatePaper, popRateGlass -> WidgetFamily.rate
            popNichePaper, popNicheGlass -> WidgetFamily.tags
            popContactPaper, popContactGlass -> WidgetFamily.contact
            popBodyPaper, popBodyGlass -> WidgetFamily.body
            proofBrandGrid, proofBrandRail, proofBrandCoins, typeMarquee -> WidgetFamily.brand
            // กำแพงโพลารอยด์อ่าน `track.works` เหมือนอีกห้าใบแล้ว — หนึ่งใบคือผลงานหนึ่งชิ้น
            proofWork, proofTicket,
            wallPolaroid -> WidgetFamily.verified
            // ตระกูลของตัวเอง — ไม่มีใบไหนเล่าเรื่องเดียวกันให้สลับได้
            proofSeal -> WidgetFamily.seal
            statGiant, socialChips, socialTiles, statWrapped, statPoster -> WidgetFamily.followers
            artFilmstrip, artDuo, artPair, workFeatured, workReel, artPhotobooth,
            galleryStack, galleryCarousel, galleryMasonry, galleryMosaic,
            galleryPost, galleryStory, galleryFilm, galleryTape,
            wallMemory, zineCover -> WidgetFamily.photo
            // ตระกูลของตัวเอง — ใบเดียวในตู้ที่ถือทั้งหัวเรื่อง รูปสี่ใบ และคำบรรยายรายชิ้น
            reelShowcase -> WidgetFamily.showcase
            typeQuote, sayClarity, sayPitch -> WidgetFamily.words
            textBlock, flowCards -> WidgetFamily.text
            // สายงาน (พิมพ์เอง) กับ หมวดหมู่ (ของแพลตฟอร์ม) สลับกันได้ — เล่าเรื่องเดียวกัน
            nicheTags, stickerTags, interestTags, nichePoster -> WidgetFamily.tags
            rateTags, rateNeon -> WidgetFamily.rate
            contactCard, contactQR,
            contactBar, contactStack, contactLine, contactChips,
            contactPoster -> WidgetFamily.contact
            audienceLine, audienceSplit, audienceAge, audienceMap, audiencePoster -> WidgetFamily.audience
        }

    /** ชั้นสิทธิ์ — ผูกกับที่มาของข้อมูล ไม่ใช่หมวดใน gallery */
    val tier: WidgetTier
        get() {
            val role = popRole
            if (role != null) return if (role == PopRole.stats || role == PopRole.rate) WidgetTier.connected else WidgetTier.personal
            return when (this) {
                proofBrandGrid, proofBrandRail, proofBrandCoins,
                proofWork, proofTicket, proofSeal,
                wallPolaroid -> WidgetTier.verified          // แพลตฟอร์มออกให้จากงานที่ส่งจริง
                statGiant, socialChips, socialTiles, statWrapped, statPoster,
                interestTags,
                // สถิติผู้ชมมาจาก OAuth · เรตมีราคาที่ระบบแนะนำกำกับ
                audienceLine, audienceSplit, audienceAge, audienceMap, audiencePoster,
                rateTags, rateNeon -> WidgetTier.connected  // ยอด OAuth · ราคาที่ระบบแนะนำ · ตั้งค่าจากโปรไฟล์
                else -> WidgetTier.personal
            }
        }

    /**
     * widget ที่ **มีพื้นผิวของตัวเองอยู่แล้ว** — chrome จึงไม่ครอบแผ่นซ้ำ
     * กติกาของการ์ดคือ *ทุกชิ้นต้องมีพื้น* — ที่นี่ตอบแค่ว่า **ใครเป็นคนวาดพื้นนั้น**
     * ก้อนข้อความอยู่ในลิสต์นี้ด้วย — มันคือตัวอักษรที่พิมพ์ลงบนการ์ดแบบ IG ไม่ใช่กล่อง
     */
    val drawsOwnSurface: Boolean
        get() {
            // แผ่นสติกเกอร์ — กล่องขาวกับป้ายหัวข้อคือพื้นผิวของมันเอง (แต่ยังอ่านพื้นผิวที่เลือกไปใช้)
            if (isPop) return true
            return when (this) {
                // รูปเต็มกรอบ/วัสดุรูป — ตัวรูปคือพื้นอยู่แล้ว
                artPortrait, artTypeOver, artPolaroid, artFilmstrip, artDuo, artPair,
                // ตระกูลคัตเอาต์ — พื้นของมันคือฉากที่ตัวคนยืนอยู่ · โปสเตอร์พอร์ตวาดกระดาษของตัวเอง
                artNameBehind, artBreakout, artPortfolio,
                // โปสเตอร์สายงาน / ผู้ติดตาม / อินไซต์ / ตรารับรอง — แผ่นเข้มคือดีไซน์ และถอดออกได้
                nichePoster,
                statPoster,
                audiencePoster,
                proofSeal,
                typeQuote, statGiant,
                // ข้อความล้วน — ตัวมันเองคือตัวอักษร ครอบกระจกแล้วกลายเป็นป้ายแทนที่จะเป็นข้อความ
                textBlock,
                // ตั๋วผลงานวาดพื้นผิวของตัวเอง (กระดาษตั๋ว)
                proofTicket,
                // สำรับ Gen Z — วัสดุของแต่ละตัวคือพื้นผิวของมันเอง
                heroAura, statWrapped, artPhotobooth, stickerTags,
                // บัตรกระดาษที่วาดพื้นผิวของตัวเอง
                contactQR,
                // โปสเตอร์ติดต่อ — แผ่นไล่เฉดของมันคือดีไซน์
                contactPoster,
                // ป้ายราคาเป็นกระดาษแข็งที่มีเงาของตัวเอง · ป้ายไฟวาดแผ่นมืดของตัวเอง
                rateTags,
                rateNeon,
                // สำรับกองรูป — ยกเว้น `โพสต์` กับ `สตอรี่` ที่เป็น *กรอบของแพลตฟอร์ม* กระจกคือกรอบนั้น
                galleryStack, galleryCarousel, galleryMasonry, galleryMosaic,
                galleryFilm, galleryTape,
                // สำรับบรรณาธิการ — ทุกใบเป็น *แผ่นกระดาษของตัวเอง*
                wallPolaroid, wallMemory, zineCover, aboutEditorial, aboutBehind,
                sayClarity, sayPitch, flowCards,
                // แผ่นโชว์คลิป — แผ่นสีเข้มของมันคือตัวงาน ไม่ใช่กรอบที่ chrome วาดให้
                reelShowcase -> true
                // ตัวหนังสือ · ชิป · แถบโลโก้ ที่เคยลอยบนการ์ดเปล่า — ตอนนี้ได้แผ่นจาก chrome เหมือนแผ่นข้อมูล
                else -> false
            }
        }

    /**
     * ชิ้นที่ให้ผู้ใช้เลือกพื้นผิวได้
     * ตัวที่มีตัวเลือกให้เลือกมากกว่าหนึ่งแบบจึงได้แถวนี้ทั้งหมด (ดู `surfaceOptions`)
     */
    val usesSurfaceChoice: Boolean get() = surfaceOptions.size > 1
    /** ใบที่มีแผ่นทึบของตัวเอง (สำรับโปสเตอร์ · บรรณาธิการ · โชว์คลิป) — ใส่ลายทางบนแผ่นได้ */
    val takesPattern: Boolean get() = surfaceOptions.contains(WidgetSurface.pane)
    /**
     * โปสเตอร์ที่คน **ยืนบนการ์ด** — รูปทึบถูกลบพื้นหลังให้อัตโนมัติ
     * ปิดได้รายชิ้นในถาด (`WidgetInstance.liftPhoto`) สำหรับคนที่อยากได้รูปในกรอบ
     */
    val liftsSubject: Boolean get() = this == artPortfolio || this == nichePoster || this == contactPoster
    /**
     * ใบที่รับ **ตราปั๊มนูน Sale Here STAR** บนแผ่นของตัวเองได้ — ปิดได้รายชิ้นในถาด (`WidgetInstance.emboss`)
     * เลือกเฉพาะใบที่มี *วัสดุทึบ* ให้ปั๊ม (แผ่นโปสเตอร์ · บล็อกสี)
     */
    val takesEmboss: Boolean
        get() = this == artPortfolio || this == statPoster || this == statWrapped

    /**
     * widget ที่อ่าน `WidgetInstance.textStyle` — แผงของมันจะมีเรื่องฟอนต์/สี/ขนาด/จัดวางเพิ่ม
     * เปิดเฉพาะตัวที่ **ทั้งใบเป็นตัวอักษรที่ผู้ใช้พิมพ์เอง** เท่านั้น
     */
    val usesTextStyle: Boolean get() = this == textBlock

    /** widget ที่แสดงรูปครีเอเตอร์หรือรูปผลงาน — เปิดให้อัปโหลดรูปของตัวเองทับรูปตั้งต้นได้ */
    val usesPhoto: Boolean
        get() {
            val role = popRole
            if (role != null) return role == PopRole.hero || role == PopRole.video || role == PopRole.work
            return when (this) {
                artPortrait, artTypeOver, artPolaroid, statGiant, typeQuote,
                artNameBehind, artBreakout, artPortfolio, nichePoster, contactPoster,
                audiencePoster,
                artFilmstrip, artDuo, artPair, workFeatured, workReel, proofWork,
                heroAura, artPhotobooth,
                // ชั้นหลักฐานตอนนี้ใช้รูปทุกตัว — ตัวที่ไม่ใช้ถูกถอดออกไปแล้ว
                proofTicket,
                // สำรับกองรูปใช้รูปทั้งแปดตัว — มันคือทั้งหมดที่ตระกูลนี้มี
                galleryStack, galleryCarousel, galleryMasonry, galleryMosaic,
                galleryPost, galleryStory, galleryFilm, galleryTape,
                // สำรับบรรณาธิการที่มีช่องรูป — สามใบกองรูป และสองหน้าแนะนำตัว
                wallPolaroid, wallMemory, zineCover, aboutEditorial, aboutBehind,
                // แผ่นโชว์คลิป — สี่ช่องในเครื่องคือรูปปกคลิปของเจ้าของการ์ด
                reelShowcase -> true
                else -> false
            }
        }

    /** widget ที่มีรูปเป็นแกนหลัก — ต้องเว้น padding เป็นศูนย์เพื่อให้รูปชนขอบ */
    val isFullBleed: Boolean
        get() = when (this) {
            // สตอรี่คือเฟรมเต็มจอของแพลตฟอร์ม — เว้นขอบเมื่อไหร่มันเลิกเป็นสตอรี่ทันที
            workFeatured, workReel, galleryStory -> true
            else -> false
        }

    val title: String
        get() = when (this) {
            artPortrait -> "ปกนิตยสาร"
            artTypeOver -> "ตัวอักษรทับภาพ"
            artPolaroid -> "โพลารอยด์"
            artNameBehind -> "ชื่ออยู่หลังคน"
            artBreakout -> "ทะลุกรอบ"
            artPortfolio -> "โปสเตอร์พอร์ต"
            heroMinimal -> "ชื่อมินิมอล"
            heroAura -> "ออร่า"
            aboutText -> "แนะนำตัว"
            interestTags -> "หมวดหมู่ที่สนใจ"
            proofBrandGrid -> "แผงโลโก้ครบ"
            proofBrandRail -> "โลโก้เลื่อน"
            proofBrandCoins -> "เหรียญโลโก้"
            proofWork -> "ผลงานที่ยืนยันแล้ว"
            proofTicket -> "ตั๋วผลงาน"
            proofSeal -> "ตรารับรอง Sale Here"
            statGiant -> "ตัวเลขยักษ์"
            socialChips -> "ผู้ติดตามแบบแถว"
            socialTiles -> "ผู้ติดตามแบบชิป"
            statWrapped -> "การ์ดสรุปยอด"
            statPoster -> "โปสเตอร์ผู้ติดตาม"
            artPhotobooth -> "ตู้ถ่ายรูป"
            stickerTags -> "สติกเกอร์สายงาน"
            artFilmstrip -> "แถบภาพ"
            artDuo -> "เบนโตะ"
            artPair -> "คู่แนวตั้ง"
            workFeatured -> "ผลงานชิ้นเด่น"
            workReel -> "คลิปแนวตั้ง"
            galleryStack -> "กองรูปซ้อน"
            galleryCarousel -> "สไลด์การ์ด"
            galleryMasonry -> "บอร์ดพิน"
            galleryMosaic -> "โมเสก"
            galleryPost -> "โพสต์โซเชียล"
            galleryStory -> "สตอรี่"
            galleryFilm -> "ฟิล์ม 35 มม."
            galleryTape -> "เทปกาว"
            reelShowcase -> "คลิปล่าสุด"
            typeMarquee -> "แถบวิ่ง"
            typeQuote -> "คำพูดตัวใหญ่"
            textBlock -> "ข้อความ"
            wallPolaroid -> "กำแพงโพลารอยด์"
            wallMemory -> "บอร์ดรูปติดหมุด"
            zineCover -> "ปกผลงาน"
            aboutEditorial -> "หน้าแนะนำตัว"
            aboutBehind -> "ชื่อหลังภาพ"
            sayClarity -> "ประโยคไฮไลต์"
            sayPitch -> "ประโยคขายงาน"
            flowCards -> "การ์ดขั้นตอน"
            nicheTags -> "สายงาน"
            nichePoster -> "โปสเตอร์สายงาน"
            rateTags -> "ป้ายราคา"
            rateNeon -> "ป้ายไฟ"
            contactCard -> "นามบัตร"
            contactQR -> "คิวอาร์การ์ด"
            contactBar -> "แถบติดต่อ"
            contactStack -> "สามบรรทัด"
            contactLine -> "ไลน์ตัวใหญ่"
            contactChips -> "ชิปช่องทาง"
            contactPoster -> "โปสเตอร์ติดต่อ"
            audienceLine -> "ประโยคเดียว"
            audienceSplit -> "สัดส่วนผู้ชม"
            audienceAge -> "ช่วงอายุผู้ชม"
            audienceMap -> "ผู้ชมในประเทศ"
            audiencePoster -> "โปสเตอร์อินไซต์"
            // สำรับสติกเกอร์ — ชื่อ = หน้าที่ + วัสดุ · สองใบในตู้ต้องแยกกันด้วยชื่อ ไม่ใช่ด้วยรูปอย่างเดียว
            popHeroPaper, popHeroGlass, popVideoPaper, popVideoGlass,
            popStatsGlass, popWorkPaper, popWorkGlass,
            popRatePaper, popRateGlass, popNichePaper, popNicheGlass,
            popBodyPaper, popBodyGlass, popContactPaper, popContactGlass -> {
                val p = popParts
                if (p == null) "" else p.first.title + " " + p.second.label
            }
        }

    val symbol: String
        get() = when (this) {
            artPortrait -> "person.crop.rectangle.stack.fill"
            artTypeOver -> "textformat.alt"
            artPolaroid -> "photo.artframe"
            artNameBehind -> "person.and.background.dotted"
            artBreakout -> "person.crop.rectangle.badge.plus"
            artPortfolio -> "person.and.background.striped.horizontal"
            heroMinimal -> "textformat"
            heroAura -> "sparkles"
            aboutText -> "text.alignleft"
            interestTags -> "heart.text.square.fill"
            proofBrandGrid -> "square.grid.3x3.fill"
            proofBrandRail -> "arrow.left.arrow.right"
            proofBrandCoins -> "circle.grid.2x1.fill"
            proofWork -> "checkmark.seal.fill"
            proofTicket -> "ticket.fill"
            proofSeal -> "checkmark.seal.fill"
            statGiant -> "number.circle.fill"
            socialChips -> "list.bullet.rectangle.fill"
            socialTiles -> "circle.grid.3x1.fill"
            statWrapped -> "list.number"
            statPoster -> "number.square.fill"
            artPhotobooth -> "camera.fill"
            stickerTags -> "seal.fill"
            artFilmstrip -> "rectangle.split.3x1.fill"
            artDuo -> "square.grid.2x2.fill"
            artPair -> "rectangle.split.2x1.fill"
            workFeatured -> "rectangle.grid.1x2.fill"
            workReel -> "play.rectangle.fill"
            galleryStack -> "square.stack.fill"
            galleryCarousel -> "square.on.square"
            galleryMasonry -> "rectangle.split.2x2.fill"
            galleryMosaic -> "circle.grid.3x3.fill"
            galleryPost -> "text.below.photo.fill"
            galleryStory -> "camera.viewfinder"
            galleryFilm -> "film.fill"
            galleryTape -> "paperclip"
            reelShowcase -> "iphone"
            typeMarquee -> "text.line.first.and.arrowtriangle.forward"
            typeQuote -> "quote.bubble.fill"
            textBlock -> "textformat.size"
            wallPolaroid -> "photo.stack"
            wallMemory -> "pin.fill"
            zineCover -> "magazine.fill"
            aboutEditorial -> "text.word.spacing"
            aboutBehind -> "person.and.background.dotted"
            sayClarity -> "highlighter"
            sayPitch -> "text.badge.star"
            flowCards -> "rectangle.3.group.fill"
            nicheTags -> "tag"
            nichePoster -> "tags.fill"
            rateTags -> "tag.fill"
            rateNeon -> "lightbulb.fill"
            contactCard -> "person.text.rectangle.fill"
            contactQR -> "qrcode"
            contactBar -> "text.append"
            contactStack -> "list.bullet"
            contactLine -> "bubble.left.fill"
            contactChips -> "capsule.portrait.fill"
            contactPoster -> "person.crop.rectangle.fill"
            audienceLine -> "text.alignleft"
            audienceSplit -> "person.2.fill"
            audienceAge -> "chart.bar.fill"
            audienceMap -> "mappin.and.ellipse"
            audiencePoster -> "chart.pie.fill"
            // สำรับสติกเกอร์ — ค่ามาจากหน้าที่ (ดู `PopRole`)
            popHeroPaper, popHeroGlass, popVideoPaper, popVideoGlass,
            popStatsGlass, popWorkPaper, popWorkGlass,
            popRatePaper, popRateGlass, popNichePaper, popNicheGlass,
            popBodyPaper, popBodyGlass, popContactPaper, popContactGlass ->
                popRole?.symbol ?: "square.fill"
        }

    /**
     * ขนาดตั้งต้นตอนหยิบออกจากตู้ — **หน่วย pt บนพื้นที่ออกแบบ** (ดู `PageLayout`)
     * เป็นค่าที่ "พอดีสวย" ไม่ใช่ค่าที่ "เล็กสุดที่ยังได้"
     * 492 = ความกว้างหน้าเต็ม (540 − ขอบ 24 สองข้าง) จึงยังเป็นตัวที่กินเต็มหน้าอยู่
     */
    val defaultSize: Size
        get() = when (this) {
            artPortrait -> Size(366f, 420f)
            artTypeOver -> Size(366f, 367f)
            artPolaroid -> Size(179f, 206f)
            // สูงกว่าตระกูลเดียวกัน — ตัวคนเต็มตัวต้องมีที่ยืน กรอบเตี้ยได้แค่ครึ่งตัวลอย
            artNameBehind -> Size(366f, 472f)
            artBreakout -> Size(366f, 472f)
            // โปสเตอร์เต็มแผ่น — คำยักษ์กินความกว้างทั้งใบ คนต้องมีที่ยืนเต็มตัวใต้คำนั้น
            artPortfolio -> Size(366f, 488f)
            heroMinimal -> Size(366f, 135f)
            heroAura -> Size(366f, 384f)
            aboutText -> Size(366f, 135f)
            interestTags -> Size(366f, 117f)
            proofBrandGrid -> Size(366f, 206f)
            proofBrandRail -> Size(366f, 81f)
            proofBrandCoins -> Size(366f, 94f)
            proofWork -> Size(366f, 295f)
            proofTicket -> Size(366f, 260f)
            // โปสเตอร์เต็มแผ่นแนวนอน — ผังของมัน (ดู `VS` ใน `VerifiedSealWidget`)
            proofSeal -> Size(366f, 232f)
            statGiant -> Size(366f, 206f)
            socialChips -> Size(366f, 224f)
            socialTiles -> Size(366f, 117f)
            statWrapped -> Size(366f, 260f)
            // โปสเตอร์เต็มแผ่นแนวนอน — ผังของมัน (ดู `SP` ใน `StatPosterWidget`)
            statPoster -> Size(366f, 214f)
            artPhotobooth -> Size(366f, 188f)
            stickerTags -> Size(366f, 135f)
            artFilmstrip -> Size(366f, 99f)
            artDuo -> Size(366f, 260f)
            artPair -> Size(366f, 188f)
            workFeatured -> Size(366f, 260f)
            workReel -> Size(117f, 313f)
            galleryStack -> Size(366f, 224f)
            galleryCarousel -> Size(366f, 206f)
            galleryMasonry -> Size(366f, 242f)
            galleryMosaic -> Size(366f, 313f)
            galleryPost -> Size(366f, 313f)
            galleryStory -> Size(179f, 295f)
            galleryFilm -> Size(366f, 117f)
            galleryTape -> Size(366f, 206f)
            // แผ่นโชว์คลิป — ผังถูกออกแบบที่ขนาดนี้เป๊ะ (ดู `Reel` ใน `ShowcaseWidgets`)
            reelShowcase -> Size(366f, 254f)
            typeMarquee -> Size(366f, 46f)
            typeQuote -> Size(366f, 206f)
            textBlock -> Size(366f, 117f)
            // สำรับบรรณาธิการ — ทุกใบเต็มความกว้างหน้า เพราะผังของมันเป็น *หน้า* ไม่ใช่ป้าย
            wallPolaroid -> Size(366f, 470f)
            wallMemory -> Size(366f, 366f)
            zineCover -> Size(366f, 430f)
            aboutEditorial -> Size(366f, 340f)
            aboutBehind -> Size(366f, 330f)
            sayClarity -> Size(366f, 200f)
            sayPitch -> Size(366f, 172f)
            flowCards -> Size(366f, 300f)
            nicheTags -> Size(366f, 81f)
            // โปสเตอร์เต็มแผ่นแนวนอน — สัดส่วนของต้นฉบับ (ดู `NP` ใน `NichePosterWidget`)
            nichePoster -> Size(366f, 221f)
            rateTags -> Size(366f, 117f)
            rateNeon -> Size(366f, 224f)
            contactCard -> Size(366f, 135f)
            contactQR -> Size(179f, 224f)
            contactBar -> Size(366f, 64f)
            contactStack -> Size(366f, 153f)
            contactLine -> Size(366f, 117f)
            contactChips -> Size(366f, 117f)
            // โปสเตอร์เต็มแผ่น — คนต้องมีที่ยืนเต็มตัวข้างคอลัมน์ช่องทาง (ดู `CP`)
            contactPoster -> Size(366f, 270f)
            audienceLine -> Size(366f, 153f)
            audienceSplit -> Size(366f, 135f)
            audienceAge -> Size(366f, 171f)
            audienceMap -> Size(366f, 188f)
            // แผ่นอินไซต์ตั้งตรง — ผังของมัน (ดู `IP` ใน `InsightPosterWidget`)
            audiencePoster -> Size(366f, 520f)
            // สำรับสติกเกอร์ — สองวัสดุใช้ผังเดียวกันเป๊ะ ขนาดจึงขึ้นกับหน้าที่อย่างเดียว
            popHeroPaper, popHeroGlass, popVideoPaper, popVideoGlass,
            popStatsGlass, popWorkPaper, popWorkGlass,
            popRatePaper, popRateGlass, popNichePaper, popNicheGlass,
            popBodyPaper, popBodyGlass, popContactPaper, popContactGlass ->
                popRole?.defaultSize ?: Size(366f, 224f)
        }

    /**
     * **สัดส่วนที่ผังถูกออกแบบไว้** — ไม่ใช่กรงที่ขังกรอบ แต่เป็นจุดอ้างอิงของการสเกล
     * กรอบยืดได้ทั้งสองแกนตามใจ แล้ว **การโชว์เป็นฝ่ายรับมือ** (ดู `WidgetChrome`)
     */
    val aspect: Float
        get() {
            val s = defaultSize
            return s.height / maxOf(s.width, 1f)
        }

    /**
     * ความสูงที่คู่กับความกว้างนี้ตามสัดส่วนที่ออกแบบไว้ — ใช้ตอนลากหมุดมุม (สเกลทั้งชิ้น)
     * และเป็นความสูงตั้งต้นของผังในเทมเพลตที่ระบุมาแค่ความกว้าง
     */
    fun height(forWidth: Float): Float = maxOf(1f, (forWidth * aspect).roundToInt().toFloat())

    /** ขนาดเต็มที่ความกว้างนี้ */
    fun size(forWidth: Float): Size = Size(forWidth, height(forWidth))

    /** ปรับขนาดได้ไหม — ก้อนข้อความปรับผ่านขนาดตัวอักษรแทน จึงไม่มีหมุดย่อขยายกล่อง */
    val canResize: Boolean get() = this != textBlock

    /**
     * **ใบที่วาดผังของตัวเองที่ขนาดออกแบบตายตัว** แล้วสเกลตามความกว้าง (สำรับโปสเตอร์)
     * ความสูงต่ำสุดของมันคือสัดส่วนที่ออกแบบไว้ที่ความกว้างนั้น — เตี้ยกว่านั้นเนื้อหาจะถูกกรอบตัด
     */
    val keepsDesignAspect: Boolean
        get() = when (this) {
            reelShowcase, nichePoster, contactPoster, statPoster, audiencePoster,
            proofSeal -> true
            else -> false
        }

    /**
     * พื้นผิวตั้งต้นตอนหยิบออกจากตู้/สลับแบบ — **กระจกเสมอ** ไม่มีชิ้นไหนเริ่มต้นแบบไม่มีพื้น
     * สำรับสติกเกอร์วาดแผ่นของตัวเอง แต่แผ่นนั้น **อ่านค่าพื้นผิวของชิ้น** ผ่าน `LocalWidgetSurface`
     */
    val defaultSurface: WidgetSurface
        // โปสเตอร์อินไซต์ — ต้นฉบับไม่มีกรอบ พื้นของมันคือสีพื้นหลังการ์ดที่เจ้าของเลือก
        get() = if (this == audiencePoster) WidgetSurface.clear else WidgetSurface.glass

    /**
     * พื้นผิวที่ใบนี้ให้เลือก — ไม่ใช่ทุกใบที่ถอดพื้นออกแล้วยังอ่านออก
     * สองกลุ่มที่ถอดไม่ได้: **สำรับสติกเกอร์** (ตัวหนังสือถ่านคงที่จูนมาสำหรับกล่องขาว) · **ปกผลงาน** (พื้นคือรูปที่อัปโหลด)
     */
    val surfaceOptions: List<WidgetSurface>
        get() {
            // สำรับสติกเกอร์ — ตัวหนังสือเป็นถ่านคงที่ที่จูนมาสำหรับกล่องขาว ถอดกล่องแล้วหายทั้งใบ
            if (isPop) return listOf(WidgetSurface.glass, WidgetSurface.dim)
            // แผ่นโชว์คลิป — แผ่นสีเข้มคือดีไซน์ของมัน ถอดออกแล้วเหลือหัวเรื่องกับเครื่องสี่เครื่อง
            if (this == reelShowcase) return listOf(WidgetSurface.glass, WidgetSurface.pane, WidgetSurface.clear)
            // โปสเตอร์พอร์ต — กระดาษของมันคือ *ดีไซน์* คำถามเดียวที่เหลือจึงเป็น "เอากระดาษไหม"
            if (this == artPortfolio) return listOf(WidgetSurface.glass, WidgetSurface.pane, WidgetSurface.clear)
            // โปสเตอร์สายงาน — เหตุผลเดียวกัน
            if (this == nichePoster) return listOf(WidgetSurface.glass, WidgetSurface.pane, WidgetSurface.clear)
            // โปสเตอร์ผู้ติดตาม — เหตุผลเดียวกัน (ผู้ใช้ขอทั้งสองแบบ: มีพื้นหลังและไม่มี)
            if (this == statPoster) return listOf(WidgetSurface.glass, WidgetSurface.pane, WidgetSurface.clear)
            // ตรารับรอง — ถอดแผ่นแล้วเหรียญกับตัวอักษรนั่งบนการ์ดตรง ๆ
            if (this == proofSeal) return listOf(WidgetSurface.glass, WidgetSurface.pane, WidgetSurface.clear)
            // โปสเตอร์อินไซต์ — เริ่มที่ไม่มีพื้น (ดู `defaultSurface`) แผ่นข้อมูลขาวอ่านออกบนทุกพื้น
            if (this == audiencePoster) return listOf(WidgetSurface.clear, WidgetSurface.glass, WidgetSurface.pane)
            // โปสเตอร์ติดต่อ — แผ่นสีเรียบคือดีไซน์ · ถอดออกแล้วหมึกพลิกตามธีมให้เอง
            if (this == contactPoster) return listOf(WidgetSurface.glass, WidgetSurface.pane, WidgetSurface.clear)
            if (isEditorial) {
                // ปกผลงาน — พื้นของมันคือรูปที่ผู้ใช้อัปโหลด ไม่ใช่กรอบ ไม่มีอะไรให้ถอด
                if (this == zineCover) return emptyList()
                // ที่เหลือ: กระดาษของมัน · กระจกใบเดียวกับทั้งการ์ด · ไม่มีพื้นเลย
                return listOf(WidgetSurface.glass, WidgetSurface.pane, WidgetSurface.clear)
            }
            // ของที่วาดวัสดุของตัวเองแบบอื่น (ฟิล์ม · ป้ายไฟ · กระดาษอัดรูป) — วัสดุคือตัวงาน ไม่ใช่กรอบที่ถอดได้
            if (drawsOwnSurface) return emptyList()
            // ใบที่ chrome ครอบแผ่นให้อยู่แล้ว — `กระจก` ของมันคือ `.glass` ตัวเดิม
            return listOf(WidgetSurface.glass, WidgetSurface.dim, WidgetSurface.clear)
        }

    /**
     * สำรับบรรณาธิการ — แปดใบที่แปลงมาจากแผ่นตัวอย่าง (ดู `EditorialWidgets`)
     * ทั้งสำรับอ่าน `LocalWidgetSurface` เองเพื่อตอบว่าจะวาดกระดาษรองไหม
     */
    val isEditorial: Boolean
        get() = when (this) {
            wallPolaroid, wallMemory, zineCover, aboutEditorial, aboutBehind,
            sayClarity, sayPitch, flowCards -> true
            else -> false
        }

    /**
     * ชื่อของตัวเลือกพื้นผิวบนถาด — ใบที่วาดกระดาษเองไม่ได้กำลังเลือก *วัสดุของแผ่น*
     * แต่กำลังตอบว่า "เอากระดาษรองไหม" คำว่า "กระจก" ตรงนั้นจึงผิดความหมาย
     */
    fun surfaceName(s: WidgetSurface): String =
        if (drawsOwnPaper && s == WidgetSurface.glass) "มีพื้น" else s.displayName

    /** ใบที่วาดกระดาษ/แผ่นพิมพ์ของตัวเอง **และถอดออกได้** — ถาดของมันถามว่า "เอาพื้นไหม" */
    val drawsOwnPaper: Boolean
        get() = isEditorial || this == artPortfolio || this == reelShowcase ||
            this == nichePoster || this == contactPoster || this == statPoster ||
            this == audiencePoster || this == proofSeal

    /** เส้นขอบเป็นของ "แผ่นข้อมูล" เท่านั้น — ของที่วาดวัสดุเองมีขอบของตัวมันอยู่แล้ว */
    val defaultBorder: Boolean get() = if (isPop) false else !drawsOwnSurface

    companion object {
        fun from(raw: String?): WidgetKind? = entries.firstOrNull { it.raw == raw }

        /**
         * อ่านชนิดจากไฟล์ — ใจดีกับการ์ดที่บันทึกไว้ก่อนสำรับสติกเกอร์จะแยกวัสดุ
         * ไฟล์เก่าเขียนแค่ `popHero` — ตอนกู้จึงเดาจากธีมของไฟล์นั้น (`corner == .soft` = กระดาษ)
         */
        fun decode(raw: String, legacyPopSkin: PopSkin = PopSkin.glass): WidgetKind? {
            from(raw)?.let { return it }
            val suffix = if (legacyPopSkin == PopSkin.paper) "Paper" else "Glass"
            return from(raw + suffix)
        }
    }
}

// MARK: - ความลึกของ widget ในสำรับ (= `extension WidgetKind` ใน Components/Motion.swift)

/**
 * ความลึกของ widget ในสำรับ
 * กติกา: **ตัวที่มีท่าเป็นของตัวเองข้างในต้องได้ `anchored`** เพราะกรอบกับข้างในเล่นพร้อมกัน
 * แล้วท่าจะซ้อนกันจนอ่านไม่ออก — กรอบเป็นแค่กล้อง ตัวแสดงคือชิ้นส่วนข้างใน
 */
val WidgetKind.entranceStyle: EntranceStyle
    get() = when (this) {
        // ท่าอยู่ข้างในทั้งหมด — บานเกล็ด · ฟิล์ม · แถบวิ่ง · มิเตอร์ · ตารางกวาด
        WidgetKind.proofWork, WidgetKind.workFeatured, WidgetKind.workReel, WidgetKind.artDuo,
        WidgetKind.artPair, WidgetKind.artFilmstrip, WidgetKind.proofBrandGrid, WidgetKind.artPolaroid,
        WidgetKind.typeMarquee, WidgetKind.proofBrandRail, WidgetKind.statGiant, WidgetKind.artTypeOver,
        // ตระกูลคัตเอาต์ — สามระนาบเดินคนละอัตราอยู่ข้างในแล้ว
        WidgetKind.artNameBehind, WidgetKind.artBreakout, WidgetKind.artPortfolio,
        // โปสเตอร์สายงาน / ผู้ติดตาม / ตั๋วผลงาน — ท่าอยู่ข้างในแล้ว กรอบต้องนิ่ง
        WidgetKind.nichePoster,
        WidgetKind.statPoster,
        WidgetKind.proofTicket,
        // ชุดใหม่อ่าน `pageScrub` เองทุกตัว (ออร่าเต้น · สรุปปี · ตู้ถ่ายรูป · สติกเกอร์)
        WidgetKind.heroAura, WidgetKind.statWrapped, WidgetKind.artPhotobooth,
        WidgetKind.stickerTags,
        // สำรับรอบสอง — ทุกตัวอ่าน `pageScrub` เองทั้งหมด
        WidgetKind.rateTags,
        WidgetKind.rateNeon,
        WidgetKind.contactCard, WidgetKind.contactQR,
        WidgetKind.contactBar, WidgetKind.contactStack, WidgetKind.contactLine, WidgetKind.contactChips,
        WidgetKind.contactPoster,
        // ตรารับรอง — วงตัวอักษรหมุน ฟอยล์รับแสงตามนิ้วอยู่ข้างในแล้ว
        WidgetKind.proofSeal,
        WidgetKind.audienceLine, WidgetKind.audienceSplit, WidgetKind.audienceAge, WidgetKind.audienceMap,
        WidgetKind.audiencePoster,
        // สำรับกองรูป — ทั้งแปดตัวมีท่าประจำวัสดุอยู่ข้างใน
        WidgetKind.galleryStack, WidgetKind.galleryCarousel, WidgetKind.galleryMasonry, WidgetKind.galleryMosaic,
        WidgetKind.galleryPost, WidgetKind.galleryStory, WidgetKind.galleryFilm, WidgetKind.galleryTape,
        // สำรับบรรณาธิการ — ทุกใบมีขบวนของตัวเองข้างใน
        WidgetKind.wallPolaroid, WidgetKind.wallMemory, WidgetKind.zineCover, WidgetKind.aboutEditorial,
        WidgetKind.aboutBehind, WidgetKind.sayClarity, WidgetKind.sayPitch, WidgetKind.flowCards,
        // แผ่นโชว์คลิป — เครื่องสี่เครื่องพลิกไล่กันอยู่ข้างในแล้ว กรอบต้องนิ่ง
        WidgetKind.reelShowcase ->
            EntranceStyle.anchored
        // ภาพใหญ่ก้อนเดียว — กรอบพาเดินทางเอง
        WidgetKind.artPortrait, WidgetKind.typeQuote ->
            EntranceStyle.deep
        // แผ่นข้อมูล — สำรับสติกเกอร์ไม่มีท่าข้างใน กรอบพาไปทั้งแผ่นเหมือนกระดาษที่ถูกปลิว
        WidgetKind.proofBrandCoins, WidgetKind.socialChips, WidgetKind.socialTiles,
        WidgetKind.interestTags, WidgetKind.nicheTags,
        WidgetKind.popHeroPaper, WidgetKind.popHeroGlass, WidgetKind.popVideoPaper, WidgetKind.popVideoGlass,
        WidgetKind.popStatsGlass, WidgetKind.popWorkPaper, WidgetKind.popWorkGlass,
        WidgetKind.popRatePaper, WidgetKind.popRateGlass, WidgetKind.popNichePaper, WidgetKind.popNicheGlass,
        WidgetKind.popBodyPaper, WidgetKind.popBodyGlass, WidgetKind.popContactPaper, WidgetKind.popContactGlass ->
            EntranceStyle.mid
        // ตัวหนังสือล้วน
        WidgetKind.heroMinimal, WidgetKind.aboutText, WidgetKind.textBlock ->
            EntranceStyle.light
    }

// MARK: - พื้นผิวของชิ้นที่กำลังวาด (ส่งลงทาง CompositionLocal — = `EnvironmentValues` ของ iOS)

/** พื้นผิวที่ผู้ใช้เลือกให้ชิ้นนี้ — widget ที่วาดแผ่นเองอ่านค่านี้แทนที่จะให้ `WidgetChrome` ครอบ (= `\.widgetSurface`) */
val LocalWidgetSurface = compositionLocalOf { WidgetSurface.glass }

/** ลายบนแผ่นของชิ้นนี้ (= `\.widgetPattern`) */
val LocalWidgetPattern = compositionLocalOf { PlatePattern.plain }

/** ใบนี้ปั๊มตรานูนไหม — ดู `WidgetKind.takesEmboss` (ตั้งต้นเปิด พรีวิวในตู้จึงเห็นตราด้วย) (= `\.widgetEmboss`) */
val LocalWidgetEmboss = compositionLocalOf { true }

/** ตราของใบนี้เป็นปั๊มนูนเปล่า (false = ตราพิมพ์ด้วยหมึกของแผ่น) (= `\.widgetEmbossBlind`) */
val LocalWidgetEmbossBlind = compositionLocalOf { false }

/** ชิ้นนี้ลบพื้นหลังรูปคนให้เองไหม — ดู `WidgetKind.liftsSubject` (= `\.widgetLiftsPhoto`) */
val LocalWidgetLiftsPhoto = compositionLocalOf { false }

/** เส้นขอบรอบชิ้น (= `\.widgetBorder`) */
val LocalWidgetBorder = compositionLocalOf { false }

/**
 * วัสดุที่ชนิดของชิ้นสั่งมา — ชิ้นส่วนร่วมของสำรับสติกเกอร์อยู่ลึกหลายชั้น
 * `null` แปลว่าไม่ได้วาดจากชนิดใดชนิดหนึ่ง (= `\.popSkin`)
 */
val LocalPopSkin = compositionLocalOf<PopSkin?> { null }

// MARK: - Plate pattern

/** ลายบนแผ่นทึบของ widget — เรียบ · ลายทาง · ข้าวหลามตัด */
enum class PlatePattern {
    plain, stripe, diamond;

    val raw: String get() = name
    val id: String get() = raw

    /** ชื่อไทยบนถาด (= `name` ของ Swift — `Enum.name` ของ Kotlin ถูกจองไว้ จึงเป็น `displayName` ตามแบบ `CardInk`) */
    val displayName: String
        get() = when (this) {
            plain -> "เรียบ"
            stripe -> "ลายทาง"
            diamond -> "ข้าวหลามตัด"
        }

    companion object {
        fun from(raw: String?): PlatePattern? = entries.firstOrNull { it.raw == raw }
    }
}

// MARK: - Surface

/**
 * พื้นผิวของ widget — ผู้ใช้เลือกทับค่าตั้งต้นของชนิดได้ทุกตัว
 * ของเดิมมี `จาง` กับ `โปร่ง` ด้วย — ทั้งคู่ถูกยุบมาเป็นกระจก (ดู `decode`) การ์ดเก่าจึงเปิดแล้วได้พื้นครบทุกชิ้นทันที
 */
enum class WidgetSurface {
    /** liquid glass */
    glass,
    /** แผ่นเข้มทึบ */
    dim,
    /**
     * **ไม่มีพื้นเลย** — เนื้อหานั่งบนการ์ดตรง ๆ ไม่มีแผ่น ไม่มีกระดาษ ไม่มีเงา
     * ตัวที่เลือกได้อยู่ที่ `WidgetKind.surfaceOptions` — ไม่ใช่ทุกใบที่ถอดพื้นแล้วยังอ่านออก
     */
    clear,
    /**
     * **กระจกของ chrome บนใบที่วาดวัสดุเอง** — กระดาษ/แผ่นพิมพ์ของมันถูกถอดออก
     * แล้วเอาเนื้อหาไปวางบนแผ่นกระจกใบเดียวกับที่ widget ตัวอื่นทั้งการ์ดใช้อยู่
     * ตอนวาด chrome ครอบกระจกให้ ส่วน widget ได้รับค่า `clear` ลงไป (ดู `WidgetChrome`)
     */
    pane;

    val raw: String get() = name
    val id: String get() = raw

    /** ชื่อไทยบนถาด (= `name` ของ Swift — `Enum.name` ของ Kotlin ถูกจองไว้ จึงเป็น `displayName` ตามแบบ `CardInk`) */
    val displayName: String
        get() = when (this) {
            glass -> "กระจก"
            dim -> "เข้ม"
            clear -> "ไม่มีพื้น"
            pane -> "กระจก"
        }

    companion object {
        fun from(raw: String?): WidgetSurface? = entries.firstOrNull { it.raw == raw }

        /** อ่านค่าจากไฟล์ — ชื่อที่เลิกใช้แล้ว (`faint`/`plain`) ตกมาเป็นกระจก ไม่ใช่ค่าว่าง */
        fun decode(raw: String): WidgetSurface = from(raw) ?: glass
    }
}

// MARK: - Instance

/**
 * ชิ้น widget หนึ่งชิ้นบนหน้า — พิกัดคือ **หน่วย pt บนพื้นที่ออกแบบ** อ้างมุมบนซ้ายของหน้า
 * เป็นพิกัดที่ผู้ใช้ *ขอ* ไม่ใช่พิกัดที่ได้จริง — `PageLayout.solve` เป็นคนตัดสินตอนวาด
 * ลำดับใน `CardPage.items` คือลำดับ "ใครได้ที่ก่อน" เวลาสองตัวขอที่เดียวกัน
 */
data class WidgetInstance(
    /** ส่งเข้ามาได้เฉพาะตอนกู้จากไฟล์ — ข้อความกับรูปของก้อนผูกกับ id นี้ (ดู `Profile.note`, `PhotoStore.perWidget`) */
    val id: UUID,
    var kind: WidgetKind,
    var x: Float,
    var y: Float,
    var w: Float,
    var h: Float,
    /** พื้นผิว — ตั้งต้นตามบุคลิกของชนิด (typography โปร่ง · แผ่นข้อมูลกระจก) */
    var surface: WidgetSurface,
    /** เส้นขอบรอบ widget — แยกจากพื้นผิว เพราะบางทีอยากได้กรอบโดยไม่เอาพื้น */
    var border: Boolean,
    /** ลายบนแผ่นทึบ — เลือกรายชิ้นในถาด (ดู `WidgetKind.takesPattern`) */
    var pattern: PlatePattern = PlatePattern.plain,
    /** ลบพื้นหลังรูปคนให้อัตโนมัติ — มีผลเฉพาะ `kind.liftsSubject` · ตั้งต้นเปิด */
    var liftPhoto: Boolean = true,
    /** ตรา Sale Here STAR บนแผ่นของใบนี้ — มีผลเฉพาะ `kind.takesEmboss` · ตั้งต้นเปิด */
    var emboss: Boolean = true,
    /** ปั๊มนูนเปล่าแทนตราพิมพ์ — ตั้งต้นเป็นตราพิมพ์ด้วยหมึกของแผ่น */
    var embossBlind: Boolean = false,
    /** หน้าตาตัวอักษร — ฟอนต์ · สี · ขนาด · การจัดวาง (อยู่ที่ชิ้น ไม่ใช่ที่ตระกูล — มันคือ *หน้าตา* ไม่ใช่ *เนื้อหา*) */
    var textStyle: WidgetTextStyle = WidgetTextStyle(),
) {
    /** กรอบที่ตัวนี้ *ขอ* — ยังไม่ผ่านการรูดเข้าหน้าและการดันไม่ให้ทับกัน */
    val rect: Rect get() = Rect(x, y, x + w, y + h)

    /** สำเนาที่ย้าย/ยืดกรอบตาม `r` (= `rect` setter ของ Swift) */
    fun withRect(r: Rect): WidgetInstance = copy(x = r.left, y = r.top, w = r.width, h = r.height)

    /**
     * ย่อ/ขยาย **ทั้งชิ้นตามสัดส่วนที่เป็นอยู่** — หมุดมุมใช้ตัวนี้
     * ใช้สัดส่วนปัจจุบันของชิ้น ไม่ใช่สัดส่วนของชนิด
     */
    fun scale(toWidth: Float): WidgetInstance {
        val ratio = h / maxOf(w, 1f)
        return copy(w = toWidth, h = maxOf(1f, (toWidth * ratio).roundToInt().toFloat()))
    }

    /** คืนความสูงให้ตรงสัดส่วนที่ออกแบบไว้ — ใช้ตอนสลับแบบ (แบบใหม่มีผังของตัวเอง) */
    fun resetAspect(): WidgetInstance = copy(h = kind.height(w))

    /** สเกลของชิ้นเทียบกับผังที่ออกแบบไว้ — 1 = ขนาดจริง */
    val scale: Float get() = w / maxOf(kind.defaultSize.width, 1f)

    companion object {
        /**
         * = `init(_ kind:x:y:w:h:id:)` ของ Swift
         * ไม่ระบุ `h` = ได้ความสูงตาม **สัดส่วนที่ออกแบบไว้** ของความกว้างนั้น ไม่ใช่ความสูงตั้งต้นดิบ ๆ
         * (ผังในเทมเพลตจึงเขียนแค่ x/y/w แล้วได้ชิ้นที่สัดส่วนถูกต้องเสมอ — ยืดทีหลังได้ตามใจ)
         */
        fun make(
            kind: WidgetKind,
            x: Float = PageLayout.margin,
            y: Float = PageLayout.margin,
            w: Float? = null,
            h: Float? = null,
            id: UUID = UUID.randomUUID(),
        ): WidgetInstance {
            val width = w ?: kind.defaultSize.width
            return WidgetInstance(
                id = id,
                kind = kind,
                x = x,
                y = y,
                w = width,
                h = h ?: kind.height(width),
                surface = kind.defaultSurface,
                border = kind.defaultBorder,
            )
        }
    }
}

// MARK: - Catalog entry

/** รายการใน Widget Gallery — "ตู้รางวัล" */
class CatalogEntry(
    val kind: WidgetKind,
    val unlocked: Boolean = true,
    /** เงื่อนไขที่ต้องทำเพื่อปลดล็อก — null เมื่อปลดล็อกแล้ว */
    val requirement: String? = null,
) {
    val id: String = kind.raw + (if (unlocked) "" else "-locked")
}
