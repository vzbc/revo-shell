#!/usr/bin/env python3
import sys
import os
import json
import datetime


def fmt_dt(dt):
    if dt is None:
        return None
    if isinstance(dt, datetime.datetime):
        if dt.tzinfo is not None:
            dt = dt.astimezone().replace(tzinfo=None)
        return dt.strftime("%Y-%m-%dT%H:%M:%S")
    return dt.isoformat()


def parse_attendee(a):
    val = str(a)
    email = val.replace("mailto:", "").replace("MAILTO:", "")
    params = a.params if hasattr(a, "params") else {}
    return {
        "email": email,
        "name": str(params.get("CN", "")),
        "status": str(params.get("PARTSTAT", "NEEDS-ACTION")),
        "rsvp": str(params.get("RSVP", "FALSE")).upper() == "TRUE",
    }


def main():
    cal_dir = sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser(
        "~/.local/share/vdirsyncer/calendar"
    )

    try:
        from icalendar import Calendar
    except ImportError:
        print(json.dumps({"error": "missing:icalendar"}))
        return

    try:
        import recurring_ical_events
        has_recurring = True
    except ImportError:
        has_recurring = False

    today = datetime.date.today()
    start = today - datetime.timedelta(days=7)
    end = today + datetime.timedelta(days=60)

    if not os.path.isdir(cal_dir):
        print(json.dumps({"error": "no_dir:" + cal_dir}))
        return

    ics_files = []
    for dirpath, _, files in os.walk(cal_dir):
        for f in files:
            if f.endswith(".ics"):
                ics_files.append((os.path.join(dirpath, f), os.path.basename(dirpath)))

    events = []
    for ics_path, cal_name in ics_files:
        try:
            with open(ics_path, "rb") as f:
                cal = Calendar.from_ical(f.read())
        except Exception:
            continue

        # Collect master RRULEs by UID before expanding, recurring_ical_events
        # strips RRULE from the per-occurrence components it generates.
        master_rrules = {}
        for comp in cal.walk():
            if comp.name == "VEVENT":
                uid = str(comp.get("UID", ""))
                rrule = comp.get("RRULE")
                if rrule and uid:
                    master_rrules[uid] = rrule

        try:
            if has_recurring:
                components = recurring_ical_events.of(cal).between(start, end)
            else:
                components = [c for c in cal.walk() if c.name == "VEVENT"]
        except Exception:
            continue

        for component in components:
            try:
                dtstart = component.get("DTSTART")
                if not dtstart:
                    continue
                dt = dtstart.dt
                all_day = isinstance(dt, datetime.date) and not isinstance(dt, datetime.datetime)

                if not has_recurring:
                    check = dt if all_day else dt.date()
                    if check < start or check > end:
                        continue

                dtend = component.get("DTEND")
                uid = str(component.get("UID", ""))
                rrule = component.get("RRULE") or master_rrules.get(uid)
                repeat = "none"
                if rrule:
                    freqs = rrule.get("FREQ", [])
                    if freqs:
                        repeat = str(freqs[0]).lower()

                desc = component.get("DESCRIPTION")
                description = str(desc).replace("\\n", "\n") if desc else ""

                loc = component.get("LOCATION")
                location = str(loc) if loc else ""

                url_prop = component.get("URL")
                url = str(url_prop) if url_prop else ""

                cls_prop = component.get("CLASS")
                cls = str(cls_prop) if cls_prop else "PUBLIC"

                transp_prop = component.get("TRANSP")
                transp = str(transp_prop) if transp_prop else "OPAQUE"

                pri_prop = component.get("PRIORITY")
                priority = int(pri_prop) if pri_prop else 0

                cats_prop = component.get("CATEGORIES")
                categories = []
                if cats_prop:
                    if hasattr(cats_prop, "__iter__") and not isinstance(cats_prop, str):
                        categories = [str(c) for c in cats_prop]
                    else:
                        categories = [str(cats_prop)]

                org_prop = component.get("ORGANIZER")
                organizer = None
                if org_prop:
                    org_params = org_prop.params if hasattr(org_prop, "params") else {}
                    organizer = {
                        "email": str(org_prop).replace("mailto:", "").replace("MAILTO:", ""),
                        "name": str(org_params.get("CN", "")),
                    }

                att_prop = component.get("ATTENDEE")
                attendees = []
                if att_prop:
                    if not isinstance(att_prop, list):
                        att_prop = [att_prop]
                    attendees = [parse_attendee(a) for a in att_prop]

                reminder_min = None
                for sub in getattr(component, "subcomponents", []):
                    if sub.name == "VALARM":
                        trigger = sub.get("TRIGGER")
                        if trigger is not None:
                            td = trigger.dt
                            if isinstance(td, datetime.timedelta):
                                reminder_min = int(-td.total_seconds() / 60)
                        break

                events.append({
                    "summary": str(component.get("SUMMARY", "No title")),
                    "start": fmt_dt(dt),
                    "end": fmt_dt(dtend.dt if dtend else None),
                    "allDay": all_day,
                    "calendar": cal_name,
                    "uid": uid,
                    "file": ics_path,
                    "recurring": bool(rrule),
                    "repeat": repeat,
                    "description": description,
                    "location": location,
                    "url": url,
                    "cls": cls,
                    "transp": transp,
                    "priority": priority,
                    "categories": categories,
                    "organizer": organizer,
                    "attendees": attendees,
                    "reminderMin": reminder_min,
                })
            except Exception:
                continue

    events.sort(key=lambda e: e["start"])
    print(json.dumps(events))


if __name__ == "__main__":
    main()
