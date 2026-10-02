package co.salehere.starcard.ui.profile.sections

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.expandVertically
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import co.salehere.starcard.components.Motion
import co.salehere.starcard.model.Availability
import co.salehere.starcard.model.IntakeCatalog
import co.salehere.starcard.model.Profile
import co.salehere.starcard.theme.Ph
import co.salehere.starcard.theme.PIcon
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.sh
import co.salehere.starcard.ui.Haptics
import co.salehere.starcard.ui.profile.PField
import co.salehere.starcard.ui.profile.PK
import co.salehere.starcard.ui.profile.PKChoiceGrid
import co.salehere.starcard.ui.profile.PKField
import co.salehere.starcard.ui.profile.PKLabel
import co.salehere.starcard.ui.profile.PKPanel
import co.salehere.starcard.ui.profile.PKSelect
import co.salehere.starcard.ui.profile.PKTile
import co.salehere.starcard.ui.profile.PKTileGrid
import co.salehere.starcard.ui.profile.PKWrap
import co.salehere.starcard.ui.profile.ProfileSection
import co.salehere.starcard.ui.profile.SectionScroll
import co.salehere.starcard.ui.profile.pkAnchor
import co.salehere.starcard.ui.profile.rememberPKFocus
import co.salehere.starcard.ui.profile.sectionIssue
import co.salehere.starcard.ui.tap

/** ปุ่มสุดท้าย "อื่น ๆ" ของข้อ `limit` — เปิดช่องพิมพ์ (= `otherOn` ของเว็บ) */
private const val otherKey = "__other"

/** Vibe การทำงาน — ข้อ `terms` (group) ของฟอร์มเว็บ: days → time · draft · limit · province */
@Composable
fun TermsSection(
    showIssues: Boolean,
    focusRequest: String?,
    onFocusRequestChange: (String?) -> Unit,
    modifier: Modifier = Modifier,
) {
    val focus = rememberPKFocus()
    val a = Profile.me.intake?.availability ?: Availability()
    var otherOn by remember { mutableStateOf(a.otherLimit.isNotEmpty()) }

    fun err(f: String): String? = sectionIssue(ProfileSection.terms, f, showIssues)

    val dayChoice = IntakeCatalog.dayOptions.firstOrNull { it.days == a.days }?.value
    val timeChoice = IntakeCatalog.timeOptions.firstOrNull { it.slots == a.slots }?.value

    SectionScroll(focus = focus, request = focusRequest, onRequestChange = onFocusRequestChange, modifier = modifier) {
        // MARK: `days` → `time`
        PKPanel(title = "ว่างรับงานวันไหน?", modifier = Modifier.pkAnchor(PField.days)) {
            PKTileGrid(items = IntakeCatalog.dayOptions) { o ->
                PKTile(icon = o.icon, title = o.label, detail = o.detail, on = dayChoice == o.value) {
                    update { it.copy(days = o.days) }
                }
            }
            val de = err(PField.days)
            if (de != null) ErrorText(de)
            AnimatedVisibility(
                visible = dayChoice != null,
                enter = fadeIn(Motion.settle.spec()) + expandVertically(Motion.settle.spec(), expandFrom = Alignment.Top),
                exit = fadeOut(Motion.settle.spec()) + shrinkVertically(Motion.settle.spec(), shrinkTowards = Alignment.Top),
            ) {
                Column(Modifier.fillMaxWidth().pkAnchor(PField.time), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    PKLabel(text = "ช่วงไหนของวัน?", required = true)
                    PKChoiceGrid(
                        items = IntakeCatalog.timeOptions.map { it.value },
                        label = { v -> IntakeCatalog.timeOptions.firstOrNull { it.value == v }?.label ?: v },
                        isOn = { timeChoice == it },
                    ) { v ->
                        val o = IntakeCatalog.timeOptions.firstOrNull { it.value == v }
                        if (o != null) update { it.copy(slots = o.slots) }
                    }
                    val te = err(PField.time)
                    if (te != null) ErrorText(te)
                }
            }
        }

        // MARK: `draft`
        PKPanel(title = "แก้งานให้ได้กี่รอบ?", subtitle = "ไม่นับกรณีงานไม่ตรงบรีฟ", modifier = Modifier.pkAnchor(PField.draft)) {
            PKChoiceGrid(
                items = IntakeCatalog.draftRounds,
                label = { "$it ครั้ง" },
                isOn = { a.draftRounds == it },
            ) { n -> update { it.copy(draftRounds = n) } }
            val e = err(PField.draft)
            if (e != null) ErrorText(e)
        }

        // MARK: `limit` (chipsother)
        PKPanel(title = "มีงานแนวไหนที่ขอผ่านไหม? 🙅‍♀️", subtitle = "เลือกได้หลายข้อ", modifier = Modifier.pkAnchor(PField.limits)) {
            // ปุ่มสุดท้าย "อื่น ๆ" เปิดช่องพิมพ์ (= `otherOn` ของเว็บ)
            PKChoiceGrid(
                items = IntakeCatalog.limits.map { it.value } + otherKey,
                label = { v -> if (v == otherKey) "✏️ อื่น ๆ (ระบุเอง)" else (IntakeCatalog.limits.firstOrNull { it.value == v }?.label ?: v) },
                isOn = { v -> if (v == otherKey) otherOn else a.limits.contains(v) },
            ) { v ->
                if (v == otherKey) {
                    otherOn = !otherOn
                    if (!otherOn) update { it.copy(otherLimit = "") }
                    return@PKChoiceGrid
                }
                update { av ->
                    when {
                        av.limits.contains(v) -> av.copy(limits = av.limits.filter { it != v })
                        // "รับได้หมดเลย" ตัดข้ออื่นทั้งหมด (= `excl`)
                        v == IntakeCatalog.noLimit -> av.copy(limits = listOf(v))
                        else -> av.copy(limits = av.limits.filter { it != IntakeCatalog.noLimit } + v)
                    }
                }
            }
            AnimatedVisibility(
                visible = otherOn,
                enter = fadeIn(Motion.settle.spec()) + expandVertically(Motion.settle.spec(), expandFrom = Alignment.Top),
                exit = fadeOut(Motion.settle.spec()) + shrinkVertically(Motion.settle.spec(), shrinkTowards = Alignment.Top),
            ) {
                PKField(
                    label = "ระบุข้อจำกัดเพิ่มเติม",
                    text = a.otherLimit,
                    onTextChange = { v -> update { it.copy(otherLimit = v) } },
                    placeholder = IntakeCatalog.otherLimitPlaceholder,
                    id = PField.otherLimit,
                    focus = focus,
                )
            }
        }

        // MARK: `province`
        PKPanel(title = "อยู่จังหวัดไหน / ไปถึงไหนได้บ้าง?") {
            // เมนูเพิ่มจังหวัด — เลือกแล้วเพิ่มเข้าชิป ตัวเมนูกลับเป็นว่างเสมอ (= `provSel`)
            PKSelect(
                label = "จังหวัด",
                options = IntakeCatalog.provinces.filter { !a.provinces.contains(it) },
                value = "",
                onValueChange = { v ->
                    if (v.isNotEmpty()) {
                        update { av ->
                            if (av.provinces.contains(v) || av.provinces.size >= IntakeCatalog.maxProvinces) av
                            else av.copy(provinces = av.provinces + v)
                        }
                    }
                },
                placeholder = "เพิ่มจังหวัด…",
                id = PField.provinces,
            )
            if (a.provinces.isNotEmpty()) {
                PKWrap(spacing = 8f, modifier = Modifier.fillMaxWidth()) {
                    a.provinces.forEach { pv ->
                        Row(
                            Modifier
                                .tap {
                                    Haptics.light()
                                    update { av -> av.copy(provinces = av.provinces.filter { it != pv }) }
                                }
                                .background(PK.pick, CircleShape)
                                .border(1.5.dp, PK.pickLine, CircleShape)
                                .padding(horizontal = 12.dp, vertical = 8.dp),
                            horizontalArrangement = Arrangement.spacedBy(5.dp),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Text(pv, style = sh(13f, SHFont.semibold), color = PK.onPick)
                            PIcon(Ph.x, size = 10f, tint = PK.onPick)
                        }
                    }
                }
            }
            Text(
                "เลือกได้สูงสุด ${IntakeCatalog.maxProvinces} จังหวัด",
                style = sh(11.5f, SHFont.medium),
                color = if (a.provinces.size >= IntakeCatalog.maxProvinces) PK.warn else PK.hint,
            )
        }
    }
}

@Composable
private fun ErrorText(e: String) {
    Text(e, style = sh(11.5f, SHFont.medium), color = PK.err)
}

private fun update(f: (Availability) -> Availability) {
    Profile.me.updateIntake { d -> d.copy(availability = f(d.availability)) }
}
