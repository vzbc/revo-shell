function nameForPath(path) {
  return String(path || "").split("/").pop().replace(/\.[^/.]+$/, "")
}
function labelForPath(path) {
  return nameForPath(path).replace(/[-_]+/g, " ").replace(/\b\w/g, function(m) { return m.toUpperCase() })
}
function loadRows(rows) {
  var images = [], seen = {}, paths = String(rows || "").split("\n")
  for (var i = 0; i < paths.length; i++) {
    var row = paths[i]; if (!row) continue
    var columns = row.split("\t"), path = columns[0]; if (!path) continue
    var parts = path.split("/")
    var workshopId = parts[parts.length - 2] || ""
    if (seen[workshopId]) continue
    seen[workshopId] = true
    images.push({
      filePath: path,
      fileName: workshopId,
      thumbnailPath: columns[1] || path,
      title: columns[2] || workshopId
    })
  }
  return images
}
function itemMatches(images, index, filterText) {
  if (!Array.isArray(images) || index < 0 || index >= images.length) return false
  var needle = String(filterText || "").toLowerCase(); if (!needle) return true
  var title = String(images[index].title || "").toLowerCase()
  var name = String(images[index].fileName || "").toLowerCase()
  return title.indexOf(needle) !== -1 || name.indexOf(needle) !== -1
}
