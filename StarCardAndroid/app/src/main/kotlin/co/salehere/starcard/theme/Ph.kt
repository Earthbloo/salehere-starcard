package co.salehere.starcard.theme

import androidx.compose.foundation.layout.size
import androidx.compose.material3.Icon
import androidx.compose.material3.LocalContentColor
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import co.salehere.starcard.R

/** น้ำหนักของไอคอน Phosphor — ชุดย่อยเดียวกับ PhosphorSwift (regular · bold · fill) */
enum class PhWeight { regular, bold, fill }

/**
 * ชุดย่อยของ Phosphor Icons ที่แอปใช้ (= `Ph` ของ PhosphorSwift) — ชื่อ case ตรงกับ iOS ทุกตัว
 * ไฟล์ vector อยู่ที่ `res/drawable/ph_<name>_<weight>.xml` (แปลงจาก SVG ต้นทาง viewBox 256)
 */
enum class Ph(val raw: String, val regular: Int, val bold: Int, val fill: Int) {
    arrowRight("arrow-right", R.drawable.ph_arrow_right_regular, R.drawable.ph_arrow_right_bold, R.drawable.ph_arrow_right_fill),
    arrowUpRight("arrow-up-right", R.drawable.ph_arrow_up_right_regular, R.drawable.ph_arrow_up_right_bold, R.drawable.ph_arrow_up_right_fill),
    arrowsClockwise("arrows-clockwise", R.drawable.ph_arrows_clockwise_regular, R.drawable.ph_arrows_clockwise_bold, R.drawable.ph_arrows_clockwise_fill),
    briefcase("briefcase", R.drawable.ph_briefcase_regular, R.drawable.ph_briefcase_bold, R.drawable.ph_briefcase_fill),
    broadcast("broadcast", R.drawable.ph_broadcast_regular, R.drawable.ph_broadcast_bold, R.drawable.ph_broadcast_fill),
    browsers("browsers", R.drawable.ph_browsers_regular, R.drawable.ph_browsers_bold, R.drawable.ph_browsers_fill),
    buildings("buildings", R.drawable.ph_buildings_regular, R.drawable.ph_buildings_bold, R.drawable.ph_buildings_fill),
    calendarDots("calendar-dots", R.drawable.ph_calendar_dots_regular, R.drawable.ph_calendar_dots_bold, R.drawable.ph_calendar_dots_fill),
    camera("camera", R.drawable.ph_camera_regular, R.drawable.ph_camera_bold, R.drawable.ph_camera_fill),
    caretDown("caret-down", R.drawable.ph_caret_down_regular, R.drawable.ph_caret_down_bold, R.drawable.ph_caret_down_fill),
    caretLeft("caret-left", R.drawable.ph_caret_left_regular, R.drawable.ph_caret_left_bold, R.drawable.ph_caret_left_fill),
    caretRight("caret-right", R.drawable.ph_caret_right_regular, R.drawable.ph_caret_right_bold, R.drawable.ph_caret_right_fill),
    caretUpDown("caret-up-down", R.drawable.ph_caret_up_down_regular, R.drawable.ph_caret_up_down_bold, R.drawable.ph_caret_up_down_fill),
    check("check", R.drawable.ph_check_regular, R.drawable.ph_check_bold, R.drawable.ph_check_fill),
    checkCircle("check-circle", R.drawable.ph_check_circle_regular, R.drawable.ph_check_circle_bold, R.drawable.ph_check_circle_fill),
    circleDashed("circle-dashed", R.drawable.ph_circle_dashed_regular, R.drawable.ph_circle_dashed_bold, R.drawable.ph_circle_dashed_fill),
    circleHalf("circle-half", R.drawable.ph_circle_half_regular, R.drawable.ph_circle_half_bold, R.drawable.ph_circle_half_fill),
    clock("clock", R.drawable.ph_clock_regular, R.drawable.ph_clock_bold, R.drawable.ph_clock_fill),
    creditCard("credit-card", R.drawable.ph_credit_card_regular, R.drawable.ph_credit_card_bold, R.drawable.ph_credit_card_fill),
    fileImage("file-image", R.drawable.ph_file_image_regular, R.drawable.ph_file_image_bold, R.drawable.ph_file_image_fill),
    hourglass("hourglass", R.drawable.ph_hourglass_regular, R.drawable.ph_hourglass_bold, R.drawable.ph_hourglass_fill),
    info("info", R.drawable.ph_info_regular, R.drawable.ph_info_bold, R.drawable.ph_info_fill),
    lightning("lightning", R.drawable.ph_lightning_regular, R.drawable.ph_lightning_bold, R.drawable.ph_lightning_fill),
    link("link", R.drawable.ph_link_regular, R.drawable.ph_link_bold, R.drawable.ph_link_fill),
    listChecks("list-checks", R.drawable.ph_list_checks_regular, R.drawable.ph_list_checks_bold, R.drawable.ph_list_checks_fill),
    lock("lock", R.drawable.ph_lock_regular, R.drawable.ph_lock_bold, R.drawable.ph_lock_fill),
    lockOpen("lock-open", R.drawable.ph_lock_open_regular, R.drawable.ph_lock_open_bold, R.drawable.ph_lock_open_fill),
    magicWand("magic-wand", R.drawable.ph_magic_wand_regular, R.drawable.ph_magic_wand_bold, R.drawable.ph_magic_wand_fill),
    paperPlaneTilt("paper-plane-tilt", R.drawable.ph_paper_plane_tilt_regular, R.drawable.ph_paper_plane_tilt_bold, R.drawable.ph_paper_plane_tilt_fill),
    pencilSimple("pencil-simple", R.drawable.ph_pencil_simple_regular, R.drawable.ph_pencil_simple_bold, R.drawable.ph_pencil_simple_fill),
    plus("plus", R.drawable.ph_plus_regular, R.drawable.ph_plus_bold, R.drawable.ph_plus_fill),
    sealCheck("seal-check", R.drawable.ph_seal_check_regular, R.drawable.ph_seal_check_bold, R.drawable.ph_seal_check_fill),
    sparkle("sparkle", R.drawable.ph_sparkle_regular, R.drawable.ph_sparkle_bold, R.drawable.ph_sparkle_fill),
    star("star", R.drawable.ph_star_regular, R.drawable.ph_star_bold, R.drawable.ph_star_fill),
    student("student", R.drawable.ph_student_regular, R.drawable.ph_student_bold, R.drawable.ph_student_fill),
    sunHorizon("sun-horizon", R.drawable.ph_sun_horizon_regular, R.drawable.ph_sun_horizon_bold, R.drawable.ph_sun_horizon_fill),
    user("user", R.drawable.ph_user_regular, R.drawable.ph_user_bold, R.drawable.ph_user_fill),
    userCircle("user-circle", R.drawable.ph_user_circle_regular, R.drawable.ph_user_circle_bold, R.drawable.ph_user_circle_fill),
    warning("warning", R.drawable.ph_warning_regular, R.drawable.ph_warning_bold, R.drawable.ph_warning_fill),
    warningCircle("warning-circle", R.drawable.ph_warning_circle_regular, R.drawable.ph_warning_circle_bold, R.drawable.ph_warning_circle_fill),
    x("x", R.drawable.ph_x_regular, R.drawable.ph_x_bold, R.drawable.ph_x_fill),
    xCircle("x-circle", R.drawable.ph_x_circle_regular, R.drawable.ph_x_circle_bold, R.drawable.ph_x_circle_fill),
    headset("headset", R.drawable.ph_headset_regular, R.drawable.ph_headset_bold, R.drawable.ph_headset_fill),
    bell("bell", R.drawable.ph_bell_regular, R.drawable.ph_bell_bold, R.drawable.ph_bell_fill),
    shareFat("share-fat", R.drawable.ph_share_fat_regular, R.drawable.ph_share_fat_bold, R.drawable.ph_share_fat_fill),
    calendarBlank("calendar-blank", R.drawable.ph_calendar_blank_regular, R.drawable.ph_calendar_blank_bold, R.drawable.ph_calendar_blank_fill),
    qrCode("qr-code", R.drawable.ph_qr_code_regular, R.drawable.ph_qr_code_bold, R.drawable.ph_qr_code_fill),
    identificationCard("identification-card", R.drawable.ph_identification_card_regular, R.drawable.ph_identification_card_bold, R.drawable.ph_identification_card_fill),
    ticket("ticket", R.drawable.ph_ticket_regular, R.drawable.ph_ticket_bold, R.drawable.ph_ticket_fill),
    squaresFour("squares-four", R.drawable.ph_squares_four_regular, R.drawable.ph_squares_four_bold, R.drawable.ph_squares_four_fill),
    list("list", R.drawable.ph_list_regular, R.drawable.ph_list_bold, R.drawable.ph_list_fill),
    at("at", R.drawable.ph_at_regular, R.drawable.ph_at_bold, R.drawable.ph_at_fill),
    chatCircleText("chat-circle-text", R.drawable.ph_chat_circle_text_regular, R.drawable.ph_chat_circle_text_bold, R.drawable.ph_chat_circle_text_fill),
    clipboardText("clipboard-text", R.drawable.ph_clipboard_text_regular, R.drawable.ph_clipboard_text_bold, R.drawable.ph_clipboard_text_fill),
    notePencil("note-pencil", R.drawable.ph_note_pencil_regular, R.drawable.ph_note_pencil_bold, R.drawable.ph_note_pencil_fill),
    imageSquare("image-square", R.drawable.ph_image_square_regular, R.drawable.ph_image_square_bold, R.drawable.ph_image_square_fill),
    videoCamera("video-camera", R.drawable.ph_video_camera_regular, R.drawable.ph_video_camera_bold, R.drawable.ph_video_camera_fill),
    chatCircle("chat-circle", R.drawable.ph_chat_circle_regular, R.drawable.ph_chat_circle_bold, R.drawable.ph_chat_circle_fill),
    shareNetwork("share-network", R.drawable.ph_share_network_regular, R.drawable.ph_share_network_bold, R.drawable.ph_share_network_fill),
    house("house", R.drawable.ph_house_regular, R.drawable.ph_house_bold, R.drawable.ph_house_fill),
    coins("coins", R.drawable.ph_coins_regular, R.drawable.ph_coins_bold, R.drawable.ph_coins_fill),
    textAlignLeft("text-align-left", R.drawable.ph_text_align_left_regular, R.drawable.ph_text_align_left_bold, R.drawable.ph_text_align_left_fill),
    usersThree("users-three", R.drawable.ph_users_three_regular, R.drawable.ph_users_three_bold, R.drawable.ph_users_three_fill),
    mapPin("map-pin", R.drawable.ph_map_pin_regular, R.drawable.ph_map_pin_bold, R.drawable.ph_map_pin_fill),
    bank("bank", R.drawable.ph_bank_regular, R.drawable.ph_bank_bold, R.drawable.ph_bank_fill),
    `package`("package", R.drawable.ph_package_regular, R.drawable.ph_package_bold, R.drawable.ph_package_fill),
    eye("eye", R.drawable.ph_eye_regular, R.drawable.ph_eye_bold, R.drawable.ph_eye_fill),
    gift("gift", R.drawable.ph_gift_regular, R.drawable.ph_gift_bold, R.drawable.ph_gift_fill),
    chartBar("chart-bar", R.drawable.ph_chart_bar_regular, R.drawable.ph_chart_bar_bold, R.drawable.ph_chart_bar_fill),
    play("play", R.drawable.ph_play_regular, R.drawable.ph_play_bold, R.drawable.ph_play_fill),
    skipForward("skip-forward", R.drawable.ph_skip_forward_regular, R.drawable.ph_skip_forward_bold, R.drawable.ph_skip_forward_fill),
    skipBack("skip-back", R.drawable.ph_skip_back_regular, R.drawable.ph_skip_back_bold, R.drawable.ph_skip_back_fill),
    phone("phone", R.drawable.ph_phone_regular, R.drawable.ph_phone_bold, R.drawable.ph_phone_fill),
    chatText("chat-text", R.drawable.ph_chat_text_regular, R.drawable.ph_chat_text_bold, R.drawable.ph_chat_text_fill),
    envelope("envelope", R.drawable.ph_envelope_regular, R.drawable.ph_envelope_bold, R.drawable.ph_envelope_fill),
    trash("trash", R.drawable.ph_trash_regular, R.drawable.ph_trash_bold, R.drawable.ph_trash_fill),
    dotsThree("dots-three", R.drawable.ph_dots_three_regular, R.drawable.ph_dots_three_bold, R.drawable.ph_dots_three_fill),
    heart("heart", R.drawable.ph_heart_regular, R.drawable.ph_heart_bold, R.drawable.ph_heart_fill),
    bookmark("bookmark", R.drawable.ph_bookmark_regular, R.drawable.ph_bookmark_bold, R.drawable.ph_bookmark_fill),
    lockSimple("lock-simple", R.drawable.ph_lock_simple_regular, R.drawable.ph_lock_simple_bold, R.drawable.ph_lock_simple_fill),
    quotes("quotes", R.drawable.ph_quotes_regular, R.drawable.ph_quotes_bold, R.drawable.ph_quotes_fill),
    filmStrip("film-strip", R.drawable.ph_film_strip_regular, R.drawable.ph_film_strip_bold, R.drawable.ph_film_strip_fill),
    tag("tag", R.drawable.ph_tag_regular, R.drawable.ph_tag_bold, R.drawable.ph_tag_fill),
    hash("hash", R.drawable.ph_hash_regular, R.drawable.ph_hash_bold, R.drawable.ph_hash_fill),
    chartPie("chart-pie", R.drawable.ph_chart_pie_regular, R.drawable.ph_chart_pie_bold, R.drawable.ph_chart_pie_fill),
    magicWand2("magic-wand2", R.drawable.ph_magic_wand2_regular, R.drawable.ph_magic_wand2_bold, R.drawable.ph_magic_wand2_fill),
    share("share", R.drawable.ph_share_regular, R.drawable.ph_share_bold, R.drawable.ph_share_fill),
    microphone("microphone", R.drawable.ph_microphone_regular, R.drawable.ph_microphone_bold, R.drawable.ph_microphone_fill),
    barbell("barbell", R.drawable.ph_barbell_regular, R.drawable.ph_barbell_bold, R.drawable.ph_barbell_fill),
    forkKnife("fork-knife", R.drawable.ph_fork_knife_regular, R.drawable.ph_fork_knife_bold, R.drawable.ph_fork_knife_fill),
    gameController("game-controller", R.drawable.ph_game_controller_regular, R.drawable.ph_game_controller_bold, R.drawable.ph_game_controller_fill),
    tShirt("t-shirt", R.drawable.ph_t_shirt_regular, R.drawable.ph_t_shirt_bold, R.drawable.ph_t_shirt_fill),
    copy("copy", R.drawable.ph_copy_regular, R.drawable.ph_copy_bold, R.drawable.ph_copy_fill),
    downloadSimple("download-simple", R.drawable.ph_download_simple_regular, R.drawable.ph_download_simple_bold, R.drawable.ph_download_simple_fill),
    handTap("hand-tap", R.drawable.ph_hand_tap_regular, R.drawable.ph_hand_tap_bold, R.drawable.ph_hand_tap_fill),
    handPointing("hand-pointing", R.drawable.ph_hand_pointing_regular, R.drawable.ph_hand_pointing_bold, R.drawable.ph_hand_pointing_fill),
    baby("baby", R.drawable.ph_baby_regular, R.drawable.ph_baby_bold, R.drawable.ph_baby_fill),
    chatsCircle("chats-circle", R.drawable.ph_chats_circle_regular, R.drawable.ph_chats_circle_bold, R.drawable.ph_chats_circle_fill),
    database("database", R.drawable.ph_database_regular, R.drawable.ph_database_bold, R.drawable.ph_database_fill),
    palette("palette", R.drawable.ph_palette_regular, R.drawable.ph_palette_bold, R.drawable.ph_palette_fill),
    plusSquare("plus-square", R.drawable.ph_plus_square_regular, R.drawable.ph_plus_square_bold, R.drawable.ph_plus_square_fill),
    ;

    fun res(weight: PhWeight): Int = when (weight) {
        PhWeight.regular -> regular
        PhWeight.bold -> bold
        PhWeight.fill -> fill
    }

    companion object {
        fun from(raw: String?): Ph? = entries.firstOrNull { it.raw == raw }
    }
}

/**
 * ไอคอน Phosphor หนึ่งตัว (= `PIcon` ของ ProfileKit.swift) — ย้อมสีตาม `LocalContentColor`
 * เหมือน `.foregroundStyle` ของ SwiftUI · ขนาดเป็น pt ของดีไซน์ (= dp)
 */
@Composable
fun PIcon(
    icon: Ph,
    size: Float = 16f,
    weight: PhWeight = PhWeight.bold,
    tint: Color = LocalContentColor.current,
    modifier: Modifier = Modifier,
) {
    Icon(
        painter = painterResource(icon.res(weight)),
        contentDescription = null,
        tint = tint,
        modifier = modifier.size(size.dp),
    )
}
