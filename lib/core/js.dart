class JS {
  static const cfgImport =
      'async function cfg_import() { try { let text = ""; await window.flutter_inappwebview.callHandler("getClipboardText").then(function(clipboardText) { text = clipboardText }); text = text.split(";"); try { cfg = JSON.parse(atob(text[0])); } catch (e) { } try { hub.cfg = JSON.parse(atob(text[1])); } catch (e) { } try { hub.import(decodeURIComponent(atob(text[2]))); } catch (e) { } save_cfg(); save_devices(); showPopup(lang.import_ok); setTimeout(() => location.reload(), 1500); } catch (e) { showPopupError(lang.import_err); } }';
  static const cfgExport =
      'async function cfg_export() { try { const textToCopy = btoa(JSON.stringify(cfg)) + ";" + btoa(JSON.stringify(hub.cfg)) + ";" + btoa(encodeURIComponent(hub.export())) var textArea = document.createElement("textarea"); textArea.value = textToCopy; document.body.appendChild(textArea); textArea.select(); document.execCommand("copy"); document.body.removeChild(textArea); showPopup(lang.clip_copy); } catch (e) { showPopupError(lang.error); } }';
  static const cfgDownload =
      'document.body.addEventListener("click", (e) => { if (e.target.hasAttribute(`download`)) { console.log(JSON.stringify({ "name": e.target.attributes.download.value, "data": e.target.attributes.href.value, })); } });';
  static const canGoBack = 'document.querySelector(`#back`).style.display;';

  static String setOffset(double topOffset) =>
      'document.getElementById("head_cont").style.paddingTop = "${topOffset}px"';
}
