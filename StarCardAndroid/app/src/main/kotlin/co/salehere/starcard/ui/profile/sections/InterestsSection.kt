package co.salehere.starcard.ui.profile.sections

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.expandVertically
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import co.salehere.starcard.components.Motion
import co.salehere.starcard.model.IntakeCatalog
import co.salehere.starcard.model.Profile
import co.salehere.starcard.model.TextSlotID
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.sh
import co.salehere.starcard.ui.profile.PField
import co.salehere.starcard.ui.profile.PK
import co.salehere.starcard.ui.profile.PKChoiceGrid
import co.salehere.starcard.ui.profile.PKField
import co.salehere.starcard.ui.profile.PKPanel
import co.salehere.starcard.ui.profile.ProfileSection
import co.salehere.starcard.ui.profile.SectionScroll
import co.salehere.starcard.ui.profile.pkAnchor
import co.salehere.starcard.ui.profile.rememberPKFocus
import co.salehere.starcard.ui.profile.sectionIssue

/** สายที่ใช่ — ข้อ `cats` (เลือกได้ 1–5 หมวด) + `fashion` (ไซซ์ ถามเฉพาะเมื่อเลือกแฟชั่น) ของฟอร์มเว็บ */
@Composable
fun InterestsSection(
    showIssues: Boolean,
    focusRequest: String?,
    onFocusRequestChange: (String?) -> Unit,
    modifier: Modifier = Modifier,
) {
    val focus = rememberPKFocus()
    val p = Profile.me
    val selected = p.intake?.interests ?: emptyList()
    val full = selected.size >= IntakeCatalog.maxInterests
    val fashion = selected.contains(IntakeCatalog.fashion)

    SectionScroll(focus = focus, request = focusRequest, onRequestChange = onFocusRequestChange, modifier = modifier) {
        Column(
            Modifier.fillMaxWidth().padding(horizontal = 4.dp).pkAnchor(PField.interests),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Text(
                "${selected.size}/${IntakeCatalog.maxInterests}",
                style = sh(12.5f, SHFont.bold),
                color = if (full) PK.redDark else PK.muted,
                textAlign = TextAlign.End,
                modifier = Modifier.fillMaxWidth(),
            )
            // ตาราง 2 คอลัมน์ · ครบโควตาแล้ว ปุ่มที่เหลือจางและกดไม่ได้ — ไม่ใช่ดูกดได้แล้วเงียบ
            PKChoiceGrid(
                items = IntakeCatalog.interests.map { it.name },
                label = { "${IntakeCatalog.icon(it)} $it" },
                isOn = { selected.contains(it) },
                isDim = { full && !selected.contains(it) },
            ) { name ->
                Profile.me.updateIntake { d ->
                    when {
                        d.interests.contains(name) -> d.copy(interests = d.interests.filter { it != name })
                        d.interests.size < IntakeCatalog.maxInterests -> d.copy(interests = d.interests + name)
                        else -> d
                    }
                }
            }
            val e = sectionIssue(ProfileSection.interests, PField.interests, showIssues)
            if (e != null) Text(e, style = sh(11.5f, SHFont.medium), color = PK.err)
        }

        // ข้อ `fashion` — `showIf: fashionOn`
        AnimatedVisibility(
            visible = fashion,
            enter = fadeIn(Motion.settle.spec()) + expandVertically(Motion.settle.spec(), expandFrom = Alignment.Top),
            exit = fadeOut(Motion.settle.spec()) + shrinkVertically(Motion.settle.spec(), shrinkTowards = Alignment.Top),
        ) {
            PKPanel(
                title = "ขอไซซ์เสื้อผ้าหน่อยน้า 👗",
                subtitle = "เฉพาะสายแฟชั่น ให้แบรนด์ส่งชุดได้ตรงไซซ์",
                modifier = Modifier.pkAnchor(PField.fashion),
            ) {
                IntakeCatalog.fashionFields.forEach { f ->
                    val id = TextSlotID(f.field)
                    PKField(
                        label = f.label,
                        required = true,
                        // ฟอร์มเก็บตัวเลขล้วน · การ์ดต้องการ "165 ซม." — ต่อหน่วยให้ตอนเขียน ตัดออกตอนอ่าน
                        text = if (p.isPlaceholder(f.field)) "" else p.raw(id).filter { it.isDigit() || it == '.' },
                        onTextChange = { v ->
                            val n = v.filter { it.isDigit() || it == '.' }
                            Profile.me.set(id, if (n.isEmpty()) "" else "$n ${f.unit}")
                        },
                        placeholder = f.placeholder,
                        keyboard = KeyboardType.Number,
                        noCorrect = true,
                        error = sectionIssue(ProfileSection.interests, PField.size(f.field), showIssues),
                        id = PField.size(f.field),
                        focus = focus,
                        onCommit = { Profile.me.commit(id) },
                    )
                }
            }
        }
    }
}
