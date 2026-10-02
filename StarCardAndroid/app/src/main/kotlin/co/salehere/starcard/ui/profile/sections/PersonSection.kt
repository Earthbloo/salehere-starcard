package co.salehere.starcard.ui.profile.sections

import android.app.DatePickerDialog
import androidx.compose.animation.animateContentSize
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.autofill.ContentType
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import co.salehere.starcard.components.Motion
import co.salehere.starcard.model.IntakeCatalog
import co.salehere.starcard.model.PersonalInfo
import co.salehere.starcard.model.Profile
import co.salehere.starcard.model.ProfileField
import co.salehere.starcard.model.TextSlotID
import co.salehere.starcard.theme.Ph
import co.salehere.starcard.theme.PIcon
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.theme.rgb
import co.salehere.starcard.theme.sh
import co.salehere.starcard.ui.Haptics
import co.salehere.starcard.ui.profile.PField
import co.salehere.starcard.ui.profile.PK
import co.salehere.starcard.ui.profile.PKChoiceGrid
import co.salehere.starcard.ui.profile.PKField
import co.salehere.starcard.ui.profile.PKFocus
import co.salehere.starcard.ui.profile.PKLabel
import co.salehere.starcard.ui.profile.PKPanel
import co.salehere.starcard.ui.profile.PKTile
import co.salehere.starcard.ui.profile.PKTileGrid
import co.salehere.starcard.ui.profile.ProfileSection
import co.salehere.starcard.ui.profile.SectionScroll
import co.salehere.starcard.ui.profile.pkAnchor
import co.salehere.starcard.ui.profile.rememberPKFocus
import co.salehere.starcard.ui.profile.sectionIssue
import co.salehere.starcard.ui.tap
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.chrono.ThaiBuddhistChronology
import java.time.format.DateTimeFormatter
import java.util.Locale

/** ทำความรู้จักกัน — ข้อ `person` (group) ของฟอร์มเว็บ: name · basic · gender · religion · job → faculty/field */
@Composable
fun PersonSection(
    showIssues: Boolean,
    focusRequest: String?,
    onFocusRequestChange: (String?) -> Unit,
    modifier: Modifier = Modifier,
) {
    val focus = rememberPKFocus()
    val p = Profile.me
    val info = p.intake?.personal ?: PersonalInfo()

    fun err(f: String): String? = sectionIssue(ProfileSection.person, f, showIssues)

    SectionScroll(focus = focus, request = focusRequest, onRequestChange = onFocusRequestChange, modifier = modifier) {
        // `name` — ทั้ง 4 ช่องบังคับเหมือนเว็บ
        PKPanel(title = "ติดต่อคุณได้ทางไหน?") {
            ProfileTextField(
                field = ProfileField.personName, label = "ชื่อ–นามสกุลจริง", placeholder = "เช่น สมหญิง ใจดี",
                contentType = ContentType.PersonFullName, error = err(PField.name),
                limit = ProfileField.personName.limit, id = PField.name, focus = focus,
            )
            ProfileTextField(
                field = ProfileField.phone, label = "เบอร์โทรศัพท์", placeholder = "08x-xxx-xxxx",
                keyboard = KeyboardType.Phone, contentType = ContentType.PhoneNumber,
                autocap = KeyboardCapitalization.None, noCorrect = true, error = err(PField.phone),
                id = PField.phone, focus = focus,
            )
            ProfileTextField(
                field = ProfileField.email, label = "อีเมล", placeholder = "you@email.com",
                keyboard = KeyboardType.Email, contentType = ContentType.EmailAddress,
                autocap = KeyboardCapitalization.None, noCorrect = true, error = err(PField.email),
                id = PField.email, focus = focus,
            )
            ProfileTextField(
                field = ProfileField.lineId, label = "Line ID", placeholder = "@yourlineid",
                autocap = KeyboardCapitalization.None, noCorrect = true, error = err(PField.line),
                limit = ProfileField.lineId.limit, id = PField.line, focus = focus,
            )
        }

        // `basic`
        PKPanel(title = "ข้อมูลพื้นฐาน") {
            Column(Modifier.fillMaxWidth().pkAnchor(PField.dob), verticalArrangement = Arrangement.spacedBy(7.dp)) {
                PKLabel(text = "วันเกิด", required = true, hint = info.age?.let { "อายุ $it ปี" })
                DobField(dob = info.dob, error = err(PField.dob) != null)
                val e = err(PField.dob)
                if (e != null) ErrorText(e)
            }
            PKField(
                label = "สัญชาติ", required = true, text = info.nationality,
                onTextChange = { v -> update { it.copy(nationality = v) } },
                placeholder = "ไทย", error = err(PField.nation), id = PField.nation, focus = focus,
            )
        }

        // `gender`
        PKPanel(title = "เพศ", modifier = Modifier.pkAnchor(PField.gender)) {
            PKChoiceGrid(items = IntakeCatalog.genders, label = { it }, isOn = { info.gender == it }) { g ->
                update { it.copy(gender = g) }
            }
            val e = err(PField.gender)
            if (e != null) ErrorText(e)
        }

        // `religion`
        PKPanel(title = "นับถือศาสนาอะไร?", subtitle = "ใช้กรองงานที่ขัดกับความเชื่อ", modifier = Modifier.pkAnchor(PField.religion)) {
            PKChoiceGrid(items = IntakeCatalog.religions, label = { it }, isOn = { info.religion == it }) { r ->
                update { it.copy(religion = r) }
            }
            val e = err(PField.religion)
            if (e != null) ErrorText(e)
        }

        // `job` → `faculty` / `field`
        PKPanel(
            title = "ตอนนี้ทำอะไรอยู่?",
            modifier = Modifier.pkAnchor(PField.job).animateContentSize(Motion.settle.spec()),
        ) {
            PKTileGrid(items = IntakeCatalog.jobs) { j ->
                PKTile(icon = j.icon, title = j.title, detail = j.detail, on = info.job == j.key) {
                    update { d ->
                        d.copy(
                            job = j.key,
                            faculty = if (j.key != "student") "" else d.faculty,
                            field = if (j.key != "work") "" else d.field,
                        )
                    }
                }
            }
            val je = err(PField.job)
            if (je != null) ErrorText(je)
            if (info.job == "student") {
                Column(Modifier.fillMaxWidth().pkAnchor(PField.faculty), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    PKLabel(text = "เรียนคณะอะไร?", required = true)
                    PKChoiceGrid(items = IntakeCatalog.faculties, label = { it }, isOn = { info.faculty == it }) { f ->
                        update { it.copy(faculty = f) }
                    }
                    val e = err(PField.faculty)
                    if (e != null) ErrorText(e)
                }
            } else if (info.job == "work") {
                Column(Modifier.fillMaxWidth().pkAnchor(PField.field), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    PKLabel(text = "ทำงานสายไหน?", required = true)
                    PKChoiceGrid(items = IntakeCatalog.fields, label = { it }, isOn = { info.field == it }) { f ->
                        update { it.copy(field = f) }
                    }
                    val e = err(PField.field)
                    if (e != null) ErrorText(e)
                }
            }
        }
    }
}

/** ช่องข้อความของโปรไฟล์ (= `p.binding(field)`) — เขียนลง `Profile.me` ทุกตัวอักษร · ออกจากช่อง = commit */
@Composable
private fun ProfileTextField(
    field: ProfileField,
    label: String,
    placeholder: String,
    keyboard: KeyboardType = KeyboardType.Text,
    contentType: ContentType? = null,
    autocap: KeyboardCapitalization = KeyboardCapitalization.Sentences,
    noCorrect: Boolean = false,
    error: String?,
    limit: Int? = null,
    id: String,
    focus: PKFocus,
) {
    val slot = TextSlotID(field)
    PKField(
        label = label, required = true, text = Profile.me.raw(slot), onTextChange = { Profile.me.set(slot, it) },
        placeholder = placeholder, keyboard = keyboard, contentType = contentType, autocap = autocap,
        noCorrect = noCorrect, error = error, limit = limit, id = id, focus = focus,
        onCommit = { Profile.me.commit(slot) },
    )
}

/**
 * วันเกิด — ยังไม่เลือก = ช่องว่างจริง ๆ (ตัวเลือกวันที่โชว์วันตั้งต้นเสมอ ผู้ใช้เลยนึกว่ากรอกแล้วแต่โดนเตือน)
 * แตะครั้งแรกตั้งไว้ 25 ปีก่อน แล้วแตะวันที่เพื่อเปิดปฏิทิน · ช่วงที่เลือกได้ 13–90 ปี
 */
@Composable
private fun DobField(dob: Long?, error: Boolean) {
    val context = LocalContext.current
    val shape = PK.shape(PK.fieldRadius)
    Box(
        Modifier
            .fillMaxWidth()
            .heightIn(min = 46.dp)
            .background(PK.fieldFill, shape)
            .border(1.6.dp, if (error) PK.red else PK.red.opacity(0.0), shape)
            .padding(horizontal = 10.dp),
        contentAlignment = Alignment.CenterStart,
    ) {
        if (dob == null) {
            Row(
                Modifier
                    .fillMaxWidth()
                    .tap {
                        Haptics.light()
                        update { it.copy(dob = epoch(LocalDate.now().minusYears(25))) }
                    }
                    .padding(horizontal = 5.dp, vertical = 12.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text("เลือกวันเกิด", style = sh(16f), color = PK.hint)
                Spacer(Modifier.weight(1f))
                PIcon(Ph.calendarDots, size = 15f, tint = PK.hint)
            }
        } else {
            val date = Instant.ofEpochMilli(dob).atZone(ZoneId.systemDefault()).toLocalDate()
            Text(
                thaiDate(date),
                style = sh(16f),
                color = PK.ink,
                modifier = Modifier
                    .tap {
                        val hi = epoch(LocalDate.now().minusYears(13))
                        val lo = epoch(LocalDate.now().minusYears(90))
                        DatePickerDialog(context, { _, y, m, d ->
                            update { it.copy(dob = epoch(LocalDate.of(y, m + 1, d))) }
                        }, date.year, date.monthValue - 1, date.dayOfMonth).apply {
                            datePicker.minDate = lo
                            datePicker.maxDate = hi
                        }.show()
                    }
                    .background(rgb(0.46, 0.46, 0.50).opacity(0.12), PK.shape(8f))
                    .padding(horizontal = 11.dp, vertical = 6.dp),
            )
        }
    }
}

/** วันที่แบบปฏิทินไทย (= `DatePicker` ที่ `Locale(identifier: "th_TH")`) — ปี พ.ศ. */
private fun thaiDate(d: LocalDate): String {
    val th = Locale.forLanguageTag("th-TH")
    return DateTimeFormatter.ofPattern("d MMM yyyy", th).withChronology(ThaiBuddhistChronology.INSTANCE).format(d)
}

private fun epoch(d: LocalDate): Long = d.atStartOfDay(ZoneId.systemDefault()).toInstant().toEpochMilli()

@Composable
private fun ErrorText(e: String) {
    Text(e, style = sh(11.5f, SHFont.medium), color = PK.err)
}

private fun update(f: (PersonalInfo) -> PersonalInfo) {
    Profile.me.updateIntake { d -> d.copy(personal = f(d.personal)) }
}
