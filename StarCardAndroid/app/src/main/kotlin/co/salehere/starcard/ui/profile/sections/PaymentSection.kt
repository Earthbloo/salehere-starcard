package co.salehere.starcard.ui.profile.sections

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.animateContentSize
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.autofill.ContentType
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.painter.BitmapPainter
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import co.salehere.starcard.components.Motion
import co.salehere.starcard.model.Fmt
import co.salehere.starcard.model.IntakeCatalog
import co.salehere.starcard.model.LocalPhotoStore
import co.salehere.starcard.model.PayKind
import co.salehere.starcard.model.PaymentInfo
import co.salehere.starcard.model.Profile
import co.salehere.starcard.model.decodeBitmap
import co.salehere.starcard.model.fitted
import co.salehere.starcard.theme.Ph
import co.salehere.starcard.theme.PhWeight
import co.salehere.starcard.theme.PIcon
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.theme.sh
import co.salehere.starcard.ui.Haptics
import co.salehere.starcard.ui.dockPress
import co.salehere.starcard.ui.profile.PField
import co.salehere.starcard.ui.profile.PK
import co.salehere.starcard.ui.profile.PKChoiceGrid
import co.salehere.starcard.ui.profile.PKErrorLine
import co.salehere.starcard.ui.profile.PKField
import co.salehere.starcard.ui.profile.PKFocus
import co.salehere.starcard.ui.profile.PKLabel
import co.salehere.starcard.ui.profile.PKNote
import co.salehere.starcard.ui.profile.PKPanel
import co.salehere.starcard.ui.profile.PKSelect
import co.salehere.starcard.ui.profile.PKTile
import co.salehere.starcard.ui.profile.PKTileGrid
import co.salehere.starcard.ui.profile.ProfileSection
import co.salehere.starcard.ui.profile.SectionScroll
import co.salehere.starcard.ui.profile.pkAnchor
import co.salehere.starcard.ui.profile.pkDashedBorder
import co.salehere.starcard.ui.profile.rememberPKFocus
import co.salehere.starcard.ui.profile.sectionIssue
import kotlinx.coroutines.launch

/**
 * การรับเงิน — ข้อ `pay` ของฟอร์มเว็บ: นามบุคคล/นามบริษัท · บัญชีที่จะให้เงินเข้า · ถ่ายหน้าสมุดบัญชี
 * ขอแค่บัญชีตอนสมัคร — เอกสารยืนยันตัวตน (`PayKind.later`) ขอตอนได้งานแรก
 */
@Composable
fun PaymentSection(
    showIssues: Boolean,
    focusRequest: String?,
    onFocusRequestChange: (String?) -> Unit,
    modifier: Modifier = Modifier,
) {
    val focus = rememberPKFocus()
    val photos = LocalPhotoStore.current
    val scope = rememberCoroutineScope()
    val pay = Profile.me.intake?.payment ?: PaymentInfo()
    // ชนิดล่าสุดค้างไว้ให้แผงจางออกได้ครบ (ล้างข้อมูลแล้ว `kind` กลับเป็น null)
    val lastKind = remember { arrayOf<PayKind?>(pay.kind) }
    pay.kind?.let { lastKind[0] = it }
    val shownKind = pay.kind ?: lastKind[0]

    fun err(f: String): String? = sectionIssue(ProfileSection.payment, f, showIssues)

    val pick = rememberLauncherForActivityResult(ActivityResultContracts.PickVisualMedia()) { uri ->
        if (uri == null) return@rememberLauncherForActivityResult
        scope.launch {
            // ย่อรูปจากกล้อง (12MP+) ให้พอกับเอกสาร — เก็บเต็มไฟล์ทั้งดิสก์และหน่วยความจำจะบวมเปล่า ๆ
            val img = decodeBitmap(uri) ?: return@launch
            photos?.setBookBank(img.fitted(1400f))
            update { it.copy(bookPhoto = true) }
            Haptics.medium()
        }
    }

    SectionScroll(focus = focus, request = focusRequest, onRequestChange = onFocusRequestChange, modifier = modifier) {
        // นามบุคคล / นามบริษัท — กระเบื้องสองช่องเหมือน Creator/Page
        Column(Modifier.fillMaxWidth().pkAnchor(PField.payKind), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            PKTileGrid(items = PayKind.entries) { k ->
                PKTile(icon = k.icon, title = k.title, on = pay.kind == k) {
                    update { it.copy(kind = k) }
                }
            }
            val e = err(PField.payKind)
            if (e != null) Text(e, style = sh(11.5f, SHFont.medium), color = PK.err, modifier = Modifier.padding(horizontal = 4.dp))
        }

        val visible = pay.kind != null
        if (shownKind != null) {
            AnimatedVisibility(visible = visible, enter = fadeIn(Motion.settle.spec()), exit = fadeOut(Motion.settle.spec())) {
                Account(shownKind, pay, focus, ::err)
            }
            AnimatedVisibility(visible = visible, enter = fadeIn(Motion.settle.spec()), exit = fadeOut(Motion.settle.spec())) {
                Documents(shownKind, pay, photos?.bookBank, err(PField.bookPhoto)) {
                    pick.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly))
                }
            }
            AnimatedVisibility(visible = visible, enter = fadeIn(Motion.settle.spec()), exit = fadeOut(Motion.settle.spec())) {
                Tax(shownKind)
            }
            AnimatedVisibility(visible = visible, enter = fadeIn(Motion.settle.spec()), exit = fadeOut(Motion.settle.spec())) {
                Later(shownKind)
            }
        }
    }
}

// MARK: บัญชี

@Composable
private fun Account(kind: PayKind, pay: PaymentInfo, focus: PKFocus, err: (String) -> String?) {
    PKPanel(title = "เงินจะเข้าบัญชีไหน", modifier = Modifier.animateContentSize(Motion.settle.spec())) {
        if (kind == PayKind.company) {
            PKField(
                label = "ชื่อนิติบุคคล", required = true, text = pay.companyName,
                onTextChange = { v -> update { it.copy(companyName = v) } },
                placeholder = "บริษัท … จำกัด", error = err(PField.companyName),
                id = PField.companyName, focus = focus,
            )
            PKField(
                label = "เลขประจำตัวผู้เสียภาษี", required = true, text = pay.taxId,
                onTextChange = { v -> update { it.copy(taxId = v.filter { c -> c.isDigit() }.take(13)) } },
                placeholder = "13 หลัก", keyboard = KeyboardType.Number, noCorrect = true,
                error = err(PField.taxId), id = PField.taxId, focus = focus,
            )
            Chips("สำนักงานใหญ่ / สาขา", IntakeCatalog.branches, pay.branch, err(PField.branch), PField.branch) { o ->
                update { it.copy(branch = o) }
            }
            PKField(
                label = "ที่อยู่ตามหนังสือรับรอง", required = true, text = pay.address,
                onTextChange = { v -> update { it.copy(address = v) } },
                placeholder = "เลขที่ ถนน แขวง เขต จังหวัด รหัสไปรษณีย์", paragraph = true,
                error = err(PField.address), id = PField.address, focus = focus,
            )
            PKField(
                label = "กรรมการผู้มีอำนาจลงนาม", required = true, text = pay.signer,
                onTextChange = { v -> update { it.copy(signer = v) } },
                placeholder = "ชื่อ–นามสกุล ตามหนังสือรับรอง", error = err(PField.signer),
                id = PField.signer, focus = focus,
            )
            Chips("จดทะเบียน VAT", IntakeCatalog.vatOptions, pay.vat, err(PField.vat), PField.vat) { o ->
                update { it.copy(vat = o) }
            }
        }
        PKSelect(
            label = "ธนาคาร", required = true, options = IntakeCatalog.banks, value = pay.bank,
            onValueChange = { v -> update { it.copy(bank = v) } },
            placeholder = "เลือกธนาคาร…", error = err(PField.bank), id = PField.bank,
        )
        // เก็บเป็นตัวเลข 10 หลัก แสดงเป็น xxx-x-xxxxx-x
        PKField(
            label = "เลขที่บัญชี", required = true, text = PaymentInfo.formatAccount(pay.accountNo),
            onTextChange = { v -> update { it.copy(accountNo = v.filter { c -> c.isDigit() }.take(10)) } },
            placeholder = "xxx-x-xxxxx-x", keyboard = KeyboardType.Number, noCorrect = true,
            error = err(PField.accountNo), id = PField.accountNo, focus = focus,
        )
        PKField(
            label = "ชื่อบัญชี", required = true, text = pay.accountName,
            onTextChange = { v -> update { it.copy(accountName = v) } },
            placeholder = if (kind == PayKind.company) "ตามชื่อนิติบุคคล" else "ตามหน้าสมุดบัญชี",
            contentType = ContentType.PersonFullName,
            error = err(PField.accountName), id = PField.accountName, focus = focus,
        )
        PKNote(
            text = if (kind == PayKind.company) "ชื่อบัญชีต้องตรงกับชื่อนิติบุคคล รวมคำว่า “บริษัท” และ “จำกัด”"
            else "ชื่อบัญชีต้องตรงกับชื่อ–นามสกุลจริง ไม่งั้นเงินโอนไม่เข้า",
            symbol = Ph.warningCircle, color = PK.warn,
        )
    }
}

@Composable
private fun Chips(label: String, options: List<String>, value: String, error: String?, id: String, onPick: (String) -> Unit) {
    Column(Modifier.fillMaxWidth().pkAnchor(id), verticalArrangement = Arrangement.spacedBy(7.dp)) {
        PKLabel(text = label, required = true)
        PKChoiceGrid(items = options, label = { it }, isOn = { value == it }) { o -> onPick(o) }
        if (error != null) Text(error, style = sh(11.5f, SHFont.medium), color = PK.err)
    }
}

// MARK: เอกสาร

@Composable
private fun Documents(kind: PayKind, pay: PaymentInfo, book: android.graphics.Bitmap?, error: String?, onPick: () -> Unit) {
    PKPanel(title = "เอกสารที่ต้องแนบ", modifier = Modifier.pkAnchor(PField.bookPhoto)) {
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.CenterVertically) {
            Thumb(book, pay.bookPhoto)
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                Row(horizontalArrangement = Arrangement.spacedBy(4.dp), verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        if (kind == PayKind.company) "ถ่ายหน้าสมุดบัญชีบริษัท" else "ถ่ายหน้าสมุดบัญชี",
                        style = sh(14.5f, SHFont.bold), color = PK.ink,
                    )
                    Text("*", style = sh(13f, SHFont.bold), color = PK.red)
                }
                Text(
                    if (pay.bookPhoto) "แนบแล้ว" else "เห็นเลขบัญชีกับชื่อบัญชีชัด ๆ ก็พอ",
                    style = sh(12f, SHFont.medium), color = if (pay.bookPhoto) PK.ok else PK.muted,
                )
            }
            Text(
                if (pay.bookPhoto) "เปลี่ยน" else "เลือกรูป",
                style = sh(12.5f, SHFont.bold),
                color = if (pay.bookPhoto) PK.ink else PK.onInk,
                maxLines = 1, softWrap = false,
                modifier = Modifier
                    .dockPress(onClick = onPick)
                    .background(if (pay.bookPhoto) PK.fieldFill else PK.ink, CircleShape)
                    .border(1.2.dp, if (pay.bookPhoto) PK.line2 else PK.line2.opacity(0.0), CircleShape)
                    .padding(horizontal = 14.dp, vertical = 9.dp),
            )
        }
        if (error != null) PKErrorLine(error)
    }
}

/** รูปย่อของหน้าสมุด · แนบแล้วแต่ไม่มีรูป (ข้อมูลตัวอย่าง) = ไอคอนเอกสารเขียว · ยังไม่แนบ = กรอบประ */
@Composable
private fun Thumb(book: android.graphics.Bitmap?, attached: Boolean) {
    val shape = PK.shape(12f)
    if (book != null) {
        val painter = remember(book) { BitmapPainter(book.asImageBitmap()) }
        Image(
            painter, contentDescription = null, contentScale = ContentScale.Crop,
            modifier = Modifier.size(56.dp).clip(shape).border(1.dp, PK.line2, shape),
        )
    } else {
        val base = Modifier.size(56.dp).background(if (attached) PK.okTint else PK.fieldFill, shape)
        Box(
            if (attached) base.border(1.dp, PK.ok.opacity(0.4), shape)
            else base.pkDashedBorder(width = 1f, color = PK.line2, radius = 12f, dash = 4f, gap = 3f),
            contentAlignment = Alignment.Center,
        ) {
            PIcon(
                if (attached) Ph.fileImage else Ph.camera, size = 22f,
                weight = if (attached) PhWeight.fill else PhWeight.bold,
                tint = if (attached) PK.ok else PK.hint,
            )
        }
    }
}

// MARK: ภาษี

/** ตัวอย่างจริงตัวเดียว — โชว์แล้วไม่งงตอนเงินเข้าไม่เท่าค่าจ้าง */
@Composable
private fun Tax(kind: PayKind) {
    val wht = kind.withholding
    val fee = 5_000
    val cut = fee * wht / 100
    PKPanel(title = "ยอดจ่ายเกิน 1,000 บาท หักภาษี ณ ที่จ่าย $wht%") {
        Column(Modifier.fillMaxWidth().clip(PK.shape(12f)).background(PK.fieldFill)) {
            TaxRow("ตัวอย่าง — ค่าจ้างงานนี้", "฿${Fmt.baht(fee)}", PK.ink)
            Box(Modifier.fillMaxWidth().height(1.dp).background(PK.line))
            TaxRow("หัก ณ ที่จ่าย $wht%", "− ฿${Fmt.baht(cut)}", PK.ink)
            Box(Modifier.fillMaxWidth().height(1.dp).background(PK.line))
            TaxRow("เงินเข้าบัญชีจริง", "฿${Fmt.baht(fee - cut)}", PK.ok, bold = true)
        }
    }
}

@Composable
private fun TaxRow(label: String, value: String, tint: Color, bold: Boolean = false) {
    Row(Modifier.fillMaxWidth().padding(horizontal = 12.dp, vertical = 10.dp), verticalAlignment = Alignment.CenterVertically) {
        Text(label, style = sh(13f, if (bold) SHFont.bold else SHFont.medium), color = if (bold) PK.ink else PK.muted)
        Spacer(Modifier.weight(1f))
        Text(value, style = sh(14f, SHFont.bold).copy(fontFeatureSettings = "tnum"), color = tint)
    }
}

// MARK: ยังไม่ต้องส่ง

@Composable
private fun Later(kind: PayKind) {
    PKPanel(title = "ขอตอนได้งานแรก") {
        Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
            kind.later.forEach { doc ->
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.Top) {
                    PIcon(Ph.hourglass, size = 12f, tint = PK.hint, modifier = Modifier.padding(top = 3.dp))
                    Text(doc, style = sh(13f, SHFont.medium), color = PK.ink2)
                }
            }
        }
    }
}

// MARK: เขียนกลับ

private fun update(f: (PaymentInfo) -> PaymentInfo) {
    Profile.me.updateIntake { d -> d.copy(payment = f(d.payment ?: PaymentInfo())) }
}
