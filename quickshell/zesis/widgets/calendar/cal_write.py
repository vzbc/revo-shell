#!/usr/bin/env python3
import sys, os, json, uuid, datetime

FREQ_MAP = {"daily": "DAILY", "weekly": "WEEKLY", "monthly": "MONTHLY", "yearly": "YEARLY"}


def fold_line(line):
    """RFC 5545 line folding: max 75 octets, continuation with CRLF + space."""
    encoded = line.encode("utf-8")
    if len(encoded) <= 75:
        return line
    parts = []
    while len(encoded) > 75:
        chunk = encoded[:75].decode("utf-8", errors="ignore")
        parts.append(chunk)
        encoded = encoded[75:]
    parts.append(encoded.decode("utf-8"))
    return "\r\n ".join(parts)


def ics_text(value):
    """Escape special characters per RFC 5545."""
    return value.replace("\\", "\\\\").replace(";", "\\;").replace(",", "\\,").replace("\n", "\\n").replace("\r", "")


def build_ics(ev, uid):
    summary = ev.get("summary", "").strip()
    date_str = ev.get("date", "")
    all_day = ev.get("allDay", False)
    start_time = ev.get("startTime", "09:00")
    end_time = ev.get("endTime", "10:00")
    repeat = ev.get("repeat", "none")
    description = ev.get("description", "").strip()
    location = ev.get("location", "").strip()
    url = ev.get("url", "").strip()
    attendees = ev.get("attendees", [])
    reminder_min = ev.get("reminderMin")
    cls = ev.get("cls", "PUBLIC")
    transp = ev.get("transp", "OPAQUE")

    try:
        date = datetime.date.fromisoformat(date_str)
    except Exception:
        return None, "invalid_date"

    if all_day:
        dtstart = "DTSTART;VALUE=DATE:" + date.strftime("%Y%m%d")
        dtend = "DTEND;VALUE=DATE:" + (date + datetime.timedelta(days=1)).strftime("%Y%m%d")
    else:
        try:
            sh, sm = [int(x) for x in start_time.split(":")]
            eh, em = [int(x) for x in end_time.split(":")]
        except Exception:
            return None, "invalid_time"
        dt_start = datetime.datetime(date.year, date.month, date.day, sh, sm)
        dt_end = datetime.datetime(date.year, date.month, date.day, eh, em)
        if dt_end <= dt_start:
            dt_end = dt_start + datetime.timedelta(hours=1)
        dtstart = "DTSTART:" + dt_start.strftime("%Y%m%dT%H%M%S")
        dtend = "DTEND:" + dt_end.strftime("%Y%m%dT%H%M%S")

    now = datetime.datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")
    lines = [
        "BEGIN:VCALENDAR", "VERSION:2.0", "PRODID:-//Quickshell Calendar//EN",
        "BEGIN:VEVENT",
        "UID:" + uid,
        fold_line("SUMMARY:" + ics_text(summary)),
        dtstart, dtend,
        "DTSTAMP:" + now,
    ]

    freq = FREQ_MAP.get((repeat or "none").lower())
    if freq:
        lines.append("RRULE:FREQ=" + freq)

    if description:
        lines.append(fold_line("DESCRIPTION:" + ics_text(description)))
    if location:
        lines.append(fold_line("LOCATION:" + ics_text(location)))
    if url:
        lines.append("URL:" + url)
    if cls and cls != "PUBLIC":
        lines.append("CLASS:" + cls)
    if transp and transp != "OPAQUE":
        lines.append("TRANSP:" + transp)

    for att in attendees:
        email = (att.get("email") or "").strip()
        name = (att.get("name") or "").strip()
        if not email:
            continue
        att_line = "ATTENDEE;PARTSTAT=NEEDS-ACTION;RSVP=TRUE"
        if name:
            att_line += ";CN=" + name
        att_line += ":mailto:" + email
        lines.append(att_line)

    if reminder_min is not None:
        try:
            rmin = int(reminder_min)
            lines += [
                "BEGIN:VALARM",
                "TRIGGER:-PT" + str(rmin) + "M",
                "ACTION:DISPLAY",
                "DESCRIPTION:Reminder",
                "END:VALARM",
            ]
        except (ValueError, TypeError):
            pass

    lines += ["END:VEVENT", "END:VCALENDAR", ""]
    return "\r\n".join(lines), None


def cmd_create(args):
    if len(args) < 2:
        print(json.dumps({"error": "usage: create <cal_dir> <json>"})); return
    cal_dir, raw = args[0], args[1]
    try:
        ev = json.loads(raw)
    except Exception as e:
        print(json.dumps({"error": "invalid_json: " + str(e)})); return

    summary = ev.get("summary", "").strip()
    if not summary:
        print(json.dumps({"error": "summary_required"})); return

    uid = ev.get("uid") or str(uuid.uuid4()) + "@quickshell"
    ics, err = build_ics(ev, uid)
    if err:
        print(json.dumps({"error": err})); return

    target_dir = os.path.join(cal_dir, ev.get("calendar", "personal"))
    os.makedirs(target_dir, exist_ok=True)
    filepath = os.path.join(target_dir, uid.replace("@", "_") + ".ics")
    try:
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(ics)
        print(json.dumps({"ok": True, "file": filepath}))
    except Exception as e:
        print(json.dumps({"error": "write_failed: " + str(e)}))


def cmd_delete(args):
    if len(args) < 1:
        print(json.dumps({"error": "usage: delete <file_path>"})); return
    try:
        os.remove(args[0])
        print(json.dumps({"ok": True}))
    except Exception as e:
        print(json.dumps({"error": "delete_failed: " + str(e)}))


def cmd_edit(args):
    if len(args) < 2:
        print(json.dumps({"error": "usage: edit <file_path> <json>"})); return
    file_path, raw = args[0], args[1]
    try:
        ev = json.loads(raw)
    except Exception as e:
        print(json.dumps({"error": "invalid_json: " + str(e)})); return

    summary = ev.get("summary", "").strip()
    if not summary:
        print(json.dumps({"error": "summary_required"})); return

    uid = ev.get("uid") or str(uuid.uuid4()) + "@quickshell"
    ics, err = build_ics(ev, uid)
    if err:
        print(json.dumps({"error": err})); return

    try:
        with open(file_path, "w", encoding="utf-8") as f:
            f.write(ics)
        print(json.dumps({"ok": True, "file": file_path}))
    except Exception as e:
        print(json.dumps({"error": "write_failed: " + str(e)}))


def main():
    if len(sys.argv) < 2:
        print(json.dumps({"error": "usage: cal_write.py <create|delete|edit> [args]"})); return
    cmd, args = sys.argv[1], sys.argv[2:]
    {"create": cmd_create, "delete": cmd_delete, "edit": cmd_edit}.get(
        cmd, lambda _: print(json.dumps({"error": "unknown: " + cmd}))
    )(args)


if __name__ == "__main__":
    main()
