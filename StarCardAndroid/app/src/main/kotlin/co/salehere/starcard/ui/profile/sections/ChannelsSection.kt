package co.salehere.starcard.ui.profile.sections

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.expandVertically
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import co.salehere.starcard.components.Motion
import co.salehere.starcard.model.CreatorKind
import co.salehere.starcard.model.FetchMode
import co.salehere.starcard.model.FollowerSource
import co.salehere.starcard.model.Fmt
import co.salehere.starcard.model.IntakeCatalog
import co.salehere.starcard.model.IntakeData
import co.salehere.starcard.model.PlatFormat
import co.salehere.starcard.model.Profile
import co.salehere.starcard.model.RateCell
import co.salehere.starcard.model.SocialEntry
import co.salehere.starcard.model.SocialType
import co.salehere.starcard.model.defaultFormat
import co.salehere.starcard.model.fetch
import co.salehere.starcard.model.formOrder
import co.salehere.starcard.model.formats
import co.salehere.starcard.model.placeholderLink
import co.salehere.starcard.model.simulateFetch
import co.salehere.starcard.theme.BrandIcon
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
import co.salehere.starcard.ui.profile.PKErrorLine
import co.salehere.starcard.ui.profile.PKField
import co.salehere.starcard.ui.profile.PKFocus
import co.salehere.starcard.ui.profile.PKNote
import co.salehere.starcard.ui.profile.PKSpinner
import co.salehere.starcard.ui.profile.PKTextInput
import co.salehere.starcard.ui.profile.PKTile
import co.salehere.starcard.ui.profile.PKTileGrid
import co.salehere.starcard.ui.profile.ProfileSection
import co.salehere.starcard.ui.profile.SectionScroll
import co.salehere.starcard.ui.profile.pkAnchor
import co.salehere.starcard.ui.profile.pkAutoSize
import co.salehere.starcard.ui.profile.pkSurface
import co.salehere.starcard.ui.profile.rememberPKFocus
import co.salehere.starcard.ui.profile.sectionIssue
import co.salehere.starcard.ui.tap
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * ช่องทางของฉัน — ข้อ `type` + `chan` (`platrate`) ของฟอร์มเว็บ
 * Creator/Page → แต่ละแพลตฟอร์มตามลำดับ `PLAT`: ลิงก์ · ยอดผู้ติดตาม (ดึงจากลิงก์ / เชื่อมบัญชี / กรอกเอง)
 * · เรทต่อรูปแบบของแพลตฟอร์มนั้น · ผ่านได้เมื่อทุกช่องที่เลือกมี ลิงก์ถูก · ยอด > 0 · เรทอย่างน้อย 1 รูปแบบ
 */
@Composable
fun ChannelsSection(
    showIssues: Boolean,
    focusRequest: String?,
    onFocusRequestChange: (String?) -> Unit,
    modifier: Modifier = Modifier,
) {
    val focus = rememberPKFocus()
    val p = Profile.me
    val platforms = SocialType.entries.sortedBy { it.formOrder }

    SectionScroll(focus = focus, request = focusRequest, onRequestChange = onFocusRequestChange, modifier = modifier) {
        // ข้อ `type` — ถามก่อนช่องทาง
        Column(Modifier.fillMaxWidth().pkAnchor(PField.kind), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Text("คุณเป็นแบบไหน?", style = sh(16f, SHFont.bold), color = PK.ink, modifier = Modifier.padding(horizontal = 4.dp))
            PKTileGrid(items = CreatorKind.entries) { k ->
                PKTile(icon = k.icon, title = k.title, on = p.intake?.kind == k) {
                    Profile.me.updateIntake { it.copy(kind = k) }
                }
            }
            val e = sectionIssue(ProfileSection.channels, PField.kind, showIssues)
            if (e != null) Text(e, style = sh(11.5f, SHFont.medium), color = PK.err, modifier = Modifier.padding(horizontal = 4.dp))
        }

        val anyIssue = sectionIssue(ProfileSection.channels, PField.channelsAny, showIssues)
        if (anyIssue != null) {
            Text(anyIssue, style = sh(12f, SHFont.semibold), color = PK.err, modifier = Modifier.padding(horizontal = 4.dp))
        }

        Column(Modifier.fillMaxWidth().pkAnchor(PField.channelsAny), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            platforms.forEach { t -> ChannelRow(type = t, showIssues = showIssues, focus = focus) }
        }
    }
}

// MARK: - แถวของแพลตฟอร์มหนึ่ง (= `rowHTML(p)`)

@Composable
private fun ChannelRow(type: SocialType, showIssues: Boolean, focus: PKFocus) {
    var busy by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()
    val p = Profile.me
    val entry: SocialEntry? = p.intake?.social(type)
    val on = entry?.enabled ?: false
    val rates: List<RateCell> = (p.intake?.rates ?: emptyList()).filter { it.platform == type }
    val priced = rates.filter { it.price > 0 }
    val done = on && entry != null && entry.link.isNotEmpty() && entry.linkError == null && entry.followers > 0 && priced.isNotEmpty()

    val linkID = PField.link(type)
    val folID = PField.followers(type)
    val ratesID = PField.rates(type)

    fun currentEntry(): SocialEntry? = Profile.me.intake?.social(type)

    /** YouTube: ดึงจากลิงก์ได้จริง — **ตอนนี้จำลอง** รอต่อ YouTube Data API */
    fun autoFetchIfPossible() {
        val e = currentEntry() ?: return
        if (type.fetch != FetchMode.api || e.link.isEmpty() || e.linkError != null || e.source == FollowerSource.api || busy) return
        busy = true
        val seed = e.link
        scope.launch {
            val n = type.simulateFetch(seed)
            Profile.me.updateIntake { d ->
                val i = d.socials.indexOfFirst { it.type == type }
                if (i < 0) return@updateIntake d
                val s = d.socials.toMutableList()
                s[i] = s[i].copy(followers = n, source = FollowerSource.api)
                autoRates(d.copy(socials = s), type)
            }
            busy = false
            Haptics.light()
        }
    }

    /** OAuth ของแพลตฟอร์ม — **ตอนนี้จำลอง** รอต่อ `createSocialAuthorizeParams` ของ backend */
    fun connect() {
        if (busy) return
        busy = true
        Haptics.light()
        val seed = currentEntry()?.link ?: type.raw
        scope.launch {
            val n = type.simulateFetch(seed)
            Profile.me.updateIntake { d ->
                val i = d.socials.indexOfFirst { it.type == type }
                if (i < 0) return@updateIntake d
                val s = d.socials.toMutableList()
                s[i] = s[i].copy(source = FollowerSource.connected, followers = if (s[i].followers == 0) n else s[i].followers)
                // เชื่อมแล้ว = ยอดของจริง เรทที่ยังไม่แก้เองเดินตามใหม่
                val r = d.rates.map { if (it.platform == type) it.copy(touched = false) else it }
                autoRates(d.copy(socials = s, rates = r), type)
            }
            busy = false
            Haptics.medium()
        }
    }

    fun toggle() {
        val wasOn = currentEntry()?.enabled ?: false
        Profile.me.updateIntake { d ->
            val i = d.socials.indexOfFirst { it.type == type }
            if (i >= 0) {
                val s = d.socials.toMutableList()
                s[i] = s[i].copy(enabled = !s[i].enabled)
                d.copy(socials = s)
            } else {
                d.copy(socials = d.socials + SocialEntry(type = type))
            }
        }
        // เปิดแถวใหม่ = พาไปที่ช่องลิงก์เลย ไม่ต้องแตะซ้ำ
        if (!wasOn && (currentEntry()?.enabled ?: false)) {
            scope.launch {
                delay(260)
                focus.focus(linkID)
            }
        }
    }

    Column(Modifier.fillMaxWidth().pkSurface()) {
        // MARK: หัวแถว
        Row(
            Modifier
                .fillMaxWidth()
                .dockPress {
                    Haptics.light()
                    toggle()
                }
                .padding(horizontal = 12.dp, vertical = 10.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(Modifier.size(36.dp).background(PK.fieldFill, PK.shape(12f)), contentAlignment = Alignment.Center) {
                BrandIcon(type.icon, size = 22f)
            }
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Text(type.name, style = sh(14.5f, SHFont.bold), color = PK.ink)
                // ข้อความใต้ชื่อช่อง — เหมือน `sub` ใน `rowHTML`
                val sub = if (done && entry != null) "${rangeText(priced)} · ${priced.size} รูปแบบ · ผู้ติดตาม ${Fmt.compact(entry.followers)}" else ""
                if (sub.isNotEmpty()) {
                    Text(sub, style = sh(12f, SHFont.semibold), color = PK.muted, maxLines = 1, overflow = TextOverflow.MiddleEllipsis)
                }
            }
            Box(
                Modifier
                    .size(22.dp)
                    .background(if (on) PK.pick else PK.pick.opacity(0.0), CircleShape)
                    .border(1.5.dp, if (on) PK.pickLine else PK.line2, CircleShape),
                contentAlignment = Alignment.Center,
            ) {
                if (on) PIcon(Ph.check, size = 10f, tint = PK.onPick)
            }
        }

        // MARK: ตัวแถว
        AnimatedVisibility(
            visible = on && entry != null,
            enter = fadeIn(Motion.settle.spec()) + expandVertically(Motion.settle.spec(), expandFrom = Alignment.Top),
            exit = fadeOut(Motion.settle.spec()) + shrinkVertically(Motion.settle.spec(), shrinkTowards = Alignment.Top),
        ) {
            val e = entry ?: SocialEntry(type = type)
            Column(
                Modifier.fillMaxWidth().padding(start = 12.dp, end = 12.dp, bottom = 12.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                Box(Modifier.fillMaxWidth().height(1.dp).background(PK.line))

                // ไม่มีป้าย "ลิงก์โปรไฟล์" — ช่องเดียวในการ์ดของแพลตฟอร์มนั้น ตัวอย่างในช่องบอกอยู่แล้ว
                PKField(
                    label = "",
                    text = e.link,
                    onTextChange = { v ->
                        Profile.me.updateIntake { d ->
                            val i = d.socials.indexOfFirst { it.type == type }
                            if (i < 0) return@updateIntake d
                            val s = d.socials.toMutableList()
                            var x = s[i].copy(link = v)
                            // ลิงก์เปลี่ยน = ยอดที่ API เคยดึงมาไม่ใช่ของช่องนี้แล้ว
                            if (x.source == FollowerSource.api) x = x.copy(source = FollowerSource.manual, followers = 0)
                            s[i] = x
                            d.copy(socials = s)
                        }
                    },
                    placeholder = type.placeholderLink,
                    keyboard = KeyboardType.Uri,
                    autocap = KeyboardCapitalization.None,
                    noCorrect = true,
                    error = e.linkError ?: sectionIssue(ProfileSection.channels, linkID, showIssues),
                    id = linkID,
                    focus = focus,
                    onCommit = { autoFetchIfPossible() },
                )

                Followers(type = type, e = e, busy = busy, showIssues = showIssues, focus = focus, onConnect = { connect() })
                RatesBlock(type = type, e = e, rates = rates, showIssues = showIssues, focus = focus)
            }
        }
    }
}

private fun rangeText(priced: List<RateCell>): String {
    val v = priced.map { it.price }
    val lo = v.minOrNull() ?: return ""
    val hi = v.maxOrNull() ?: return ""
    return if (hi > lo) "฿${Fmt.baht(lo)}–฿${Fmt.baht(hi)}" else "฿${Fmt.baht(lo)}"
}

// MARK: ยอดผู้ติดตาม (= `folBlock`)

@Composable
private fun Followers(type: SocialType, e: SocialEntry, busy: Boolean, showIssues: Boolean, focus: PKFocus, onConnect: () -> Unit) {
    val folID = PField.followers(type)
    val issue = sectionIssue(ProfileSection.channels, folID, showIssues)
    when (type.fetch) {
        FetchMode.api -> {
            // YouTube: ดึงจากลิงก์ — ยังไม่มีลิงก์ = ไม่ต้องมีแถวบอกว่าจะดึง
            Column(Modifier.fillMaxWidth().pkAnchor(folID), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                if (busy) {
                    Row(
                        Modifier.padding(horizontal = 4.dp),
                        horizontalArrangement = Arrangement.spacedBy(7.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        PKSpinner(diameter = 14f)
                        Text("กำลังดึงยอดผู้ติดตาม…", style = sh(12.5f, SHFont.medium), color = PK.muted)
                    }
                } else if (e.followers > 0) {
                    VerifiedRow(e, note = "ยืนยันจาก YouTube")
                }
                if (issue != null) PKErrorLine(issue)
            }
        }
        FetchMode.connect -> {
            if (e.source == FollowerSource.connected) {
                VerifiedRow(e, note = "เชื่อมบัญชีแล้ว", modifier = Modifier.pkAnchor(folID))
            } else {
                // ช่องยอด + ปุ่มเชื่อมบัญชีแถวเดียว
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.Top) {
                    FollowersField(type = type, e = e, issue = issue, focus = focus, modifier = Modifier.weight(1f))
                    Row(
                        Modifier
                            .height(46.dp)
                            .dockPress(enabled = !busy) { onConnect() }
                            .background(PK.fieldFill, CircleShape)
                            .border(1.2.dp, PK.line2, CircleShape)
                            .padding(horizontal = 12.dp),
                        horizontalArrangement = Arrangement.spacedBy(5.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        if (busy) PKSpinner(diameter = 12f) else PIcon(Ph.link, size = 12f, tint = PK.ink)
                        Text("เชื่อมบัญชี", style = sh(12.5f, SHFont.bold), color = PK.ink, maxLines = 1, softWrap = false)
                    }
                }
            }
        }
        FetchMode.manual -> FollowersField(type = type, e = e, issue = issue, focus = focus)
    }
}

/** ตัวเลขล้วน — พิมพ์ยอดแล้วเรทแนะนำเดินตามทันที */
@Composable
private fun FollowersField(type: SocialType, e: SocialEntry, issue: String?, focus: PKFocus, modifier: Modifier = Modifier) {
    PKField(
        label = "",
        text = if (e.followers > 0) e.followers.toString() else "",
        onTextChange = { v ->
            val n = v.filter { it.isDigit() }.take(9).toIntOrNull() ?: 0
            Profile.me.updateIntake { d ->
                val i = d.socials.indexOfFirst { it.type == type }
                if (i < 0) return@updateIntake d
                val s = d.socials.toMutableList()
                s[i] = s[i].copy(
                    followers = n,
                    source = if (s[i].source != FollowerSource.connected) FollowerSource.manual else s[i].source,
                )
                autoRates(d.copy(socials = s), type)
            }
        },
        placeholder = "24800",
        keyboard = KeyboardType.Number,
        autocap = KeyboardCapitalization.None,
        noCorrect = true,
        error = issue,
        leading = "ผู้ติดตาม",
        id = PField.followers(type),
        focus = focus,
        modifier = modifier,
    )
}

/** ยอดที่ระบบยืนยันแล้ว — แถวเขียวบรรทัดเดียว ยอด · ระดับ ซ้าย / ที่มาของยอดขวา */
@Composable
private fun VerifiedRow(e: SocialEntry, note: String, modifier: Modifier = Modifier) {
    Row(
        modifier
            .fillMaxWidth()
            .height(40.dp)
            .background(PK.okTint, PK.shape(PK.fieldRadius))
            .padding(horizontal = 12.dp),
        horizontalArrangement = Arrangement.spacedBy(7.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        PIcon(Ph.sealCheck, size = 15f, weight = PhWeight.fill, tint = PK.ok)
        Text(
            "${Fmt.compact(e.followers)} ผู้ติดตาม · ${IntakeCatalog.tier(e.followers)}",
            style = sh(13.5f, SHFont.bold), color = PK.ink, maxLines = 1, overflow = TextOverflow.Ellipsis,
            modifier = Modifier.weight(1f, fill = false),
        )
        Spacer(Modifier.weight(1f))
        Text(note, style = sh(11f, SHFont.semibold), color = PK.ok, maxLines = 1, softWrap = false)
    }
}

// MARK: เรท (= `fmthead` + `allbtn` + `fmts` + `dev`)

@Composable
private fun RatesBlock(type: SocialType, e: SocialEntry, rates: List<RateCell>, showIssues: Boolean, focus: PKFocus) {
    val base = IntakeCatalog.recoRate(type, followers = e.followers)
    val ratesID = PField.rates(type)
    Column(Modifier.fillMaxWidth().pkAnchor(ratesID), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        // หัวเรท + ปุ่มเรทแนะนำแถวเดียว (ปุ่มเต็มแถวกินอีก 40pt ต่อแพลตฟอร์ม)
        Row(
            Modifier.fillMaxWidth().padding(horizontal = 4.dp),
            horizontalArrangement = Arrangement.spacedBy(4.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text("เรทต่องาน", style = sh(14f, SHFont.bold), color = PK.ink)
            Text("*", style = sh(13f, SHFont.bold), color = PK.red)
            Spacer(Modifier.weight(1f))
            if (base > 0) {
                Text(
                    "✨ ใช้เรทแนะนำ",
                    style = sh(12.5f, SHFont.bold), color = PK.ink, maxLines = 1, softWrap = false,
                    modifier = Modifier
                        .dockPress {
                            Haptics.light()
                            fillAll(type, e)
                        }
                        .background(PK.fieldFill, CircleShape)
                        .border(1.dp, PK.line2, CircleShape)
                        .padding(horizontal = 11.dp, vertical = 6.dp),
                )
            }
        }

        // รูปแบบงานเป็นรายการในกล่องเดียว แถวละบรรทัด — เรทตลาดอยู่ในช่องราคาเป็นตัวอย่าง
        Column(Modifier.fillMaxWidth().background(PK.fieldFill.opacity(0.6), PK.shape(PK.fieldRadius))) {
            type.formats.forEachIndexed { i, f ->
                if (i > 0) Box(Modifier.fillMaxWidth().padding(start = 40.dp).height(1.dp).background(PK.line))
                FormatRow(type = type, e = e, f = f, rates = rates, focus = focus)
            }
        }
        val issue = sectionIssue(ProfileSection.channels, ratesID, showIssues)
        if (issue != null) PKErrorLine(issue)
        val dev = deviation(type, e, rates)
        if (dev != null) PKNote(text = dev, symbol = Ph.warning, color = PK.warn)
    }
}

@Composable
private fun FormatRow(type: SocialType, e: SocialEntry, f: PlatFormat, rates: List<RateCell>, focus: PKFocus) {
    val cell = rates.firstOrNull { it.formatKey == f.key }
    val on = cell != null
    val reco = IntakeCatalog.reco(type, followers = e.followers, format = f)
    val priceID = PField.price(type, f.key)
    val boxFill by animateColorAsState(if (on) PK.surface else PK.surface.opacity(0.0), Motion.snap.spec(), label = "priceFill")
    val boxEdge by animateColorAsState(if (on) PK.ink.opacity(0.5) else PK.line, Motion.snap.spec(), label = "priceEdge")
    Row(
        Modifier.fillMaxWidth().height(44.dp).padding(horizontal = 10.dp),
        horizontalArrangement = Arrangement.spacedBy(10.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Row(
            Modifier
                .weight(1f)
                .fillMaxHeight()
                .tap {
                    Haptics.light()
                    toggleFormat(type, f, reco)
                },
            horizontalArrangement = Arrangement.spacedBy(10.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(
                Modifier
                    .size(20.dp)
                    .background(if (on) PK.pick else PK.pick.opacity(0.0), PK.shape(6f))
                    .border(1.5.dp, if (on) PK.pickLine else PK.line2, PK.shape(6f)),
                contentAlignment = Alignment.Center,
            ) {
                if (on) PIcon(Ph.check, size = 10f, tint = PK.onPick)
            }
            Text(
                f.label,
                style = sh(13.5f, if (on) SHFont.bold else SHFont.medium),
                color = if (on) PK.ink else PK.muted,
                maxLines = 1,
                autoSize = pkAutoSize(13.5f, 0.8f),
                modifier = Modifier.weight(1f),
            )
        }
        Row(
            Modifier
                .height(32.dp)
                .background(boxFill, PK.shape(9f))
                .border(1.dp, boxEdge, PK.shape(9f))
                .padding(horizontal = 9.dp),
            horizontalArrangement = Arrangement.spacedBy(3.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text("฿", style = sh(13f, SHFont.semibold), color = PK.hint)
            PKTextInput(
                text = if (cell != null && cell.price > 0) cell.price.toString() else "",
                onTextChange = { v -> setPrice(type, f, v) },
                style = sh(14.5f, SHFont.semibold),
                color = PK.ink,
                placeholder = if (reco > 0) Fmt.baht(reco) else "0",
                placeholderStyle = sh(14.5f),
                placeholderColor = PK.hint.opacity(0.6),
                keyboard = KeyboardType.Number,
                autocap = KeyboardCapitalization.None,
                noCorrect = true,
                textAlign = TextAlign.End,
                onDone = { focus.clear() },
                modifier = Modifier
                    .width(64.dp)
                    .focusRequester(focus.requester(priceID))
                    .onFocusChanged { st ->
                        if (st.isFocused) focus.current = priceID
                        else if (focus.current == priceID) focus.current = null
                    },
            )
        }
    }
}

/** เรทที่ตั้งไว้ห่างจากที่คนอื่นรับมาก — บอกแต่ไม่ห้าม (= `.dev.lo` / `.dev.hi`) */
private fun deviation(type: SocialType, e: SocialEntry, rates: List<RateCell>): String? {
    for (f in type.formats) {
        val c = rates.firstOrNull { it.formatKey == f.key } ?: continue
        if (c.price <= 0) continue
        val reco = IntakeCatalog.reco(type, followers = e.followers, format = f)
        if (reco <= 0) continue
        if (c.price < IntakeCatalog.recoLow(reco)) {
            return "เรท “${f.label}” ต่ำกว่าที่คนอื่นเขารับกันพอสมควรนะ ถ้าตั้งใจก็ไปต่อได้เลย"
        }
        if (c.price > IntakeCatalog.recoHigh(reco)) {
            return "เรท “${f.label}” สูงกว่าที่คนส่วนใหญ่รับ แบรนด์อาจขอต่อรอง — ตั้งไว้แบบนี้ก็ได้"
        }
    }
    return null
}

// MARK: เขียนกลับ

private fun setPrice(type: SocialType, f: PlatFormat, v: String) {
    val n = v.filter { it.isDigit() }.take(7).toIntOrNull() ?: 0
    Profile.me.updateIntake { d ->
        val i = d.rates.indexOfFirst { it.platform == type && it.formatKey == f.key }
        if (i >= 0) {
            val r = d.rates.toMutableList()
            r[i] = r[i].copy(price = n, touched = true)
            d.copy(rates = r)
        } else if (n > 0) {
            // พิมพ์ราคาลงรูปแบบที่ยังไม่ติ๊ก = ติ๊กให้เลย
            sortRates(d.copy(rates = d.rates + RateCell(platform = type, formatKey = f.key, price = n, touched = true)))
        } else {
            d
        }
    }
}

private fun toggleFormat(type: SocialType, f: PlatFormat, reco: Int) {
    Profile.me.updateIntake { d ->
        val i = d.rates.indexOfFirst { it.platform == type && it.formatKey == f.key }
        if (i >= 0) {
            d.copy(rates = d.rates.filterIndexed { k, _ -> k != i })
        } else {
            sortRates(d.copy(rates = d.rates + RateCell(platform = type, formatKey = f.key, price = reco, touched = false)))
        }
    }
}

/** ปุ่มเดียวเติมครบทุกฟอร์แมต ไม่ใช่แค่ฟอร์แมตที่ติ๊กไว้ — ราคาที่ผู้ใช้แก้เองแล้วไม่ทับ */
private fun fillAll(type: SocialType, e: SocialEntry) {
    Profile.me.updateIntake { d ->
        val r = d.rates.toMutableList()
        for (f in type.formats) {
            val reco = IntakeCatalog.reco(type, followers = e.followers, format = f)
            val i = r.indexOfFirst { it.platform == type && it.formatKey == f.key }
            if (i >= 0) {
                if (!r[i].touched) r[i] = r[i].copy(price = reco)
            } else {
                r.add(RateCell(platform = type, formatKey = f.key, price = reco, touched = false))
            }
        }
        sortRates(d.copy(rates = r))
    }
}

/** รู้ยอดแล้ว: ครั้งแรกติ๊กรูปแบบหลักให้ · รูปแบบที่ติ๊กไว้และยังไม่แก้เอง ปรับตามเรทแนะนำใหม่ (= `autoRates`) */
private fun autoRates(d: IntakeData, t: SocialType): IntakeData {
    val e = d.social(t) ?: return d
    if (e.followers <= 0) return d
    val mine = d.rates.filter { it.platform == t }
    val rates = if (mine.isEmpty()) {
        val f = t.defaultFormat
        d.rates + RateCell(platform = t, formatKey = f.key, price = IntakeCatalog.reco(t, followers = e.followers, format = f), touched = false)
    } else {
        d.rates.map { c ->
            val spec = c.spec
            if (c.platform == t && !c.touched && spec != null) c.copy(price = IntakeCatalog.reco(t, followers = e.followers, format = spec)) else c
        }
    }
    return sortRates(d.copy(rates = rates))
}

/** เรียงตามลำดับแพลตฟอร์มของฟอร์ม แล้วตามลำดับรูปแบบใน `PLAT.fmts` */
private fun sortRates(d: IntakeData): IntakeData {
    fun idx(c: RateCell): Int = c.platform.formats.indexOfFirst { it.key == c.formatKey }.let { if (it < 0) 0 else it }
    return d.copy(rates = d.rates.sortedWith(compareBy<RateCell>({ it.platform.formOrder }, { idx(it) })))
}
