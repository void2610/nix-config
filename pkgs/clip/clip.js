#!/usr/bin/osascript -l JavaScript
// clip <パス>: テキストは中身の文字列、画像は画像データ、それ以外は Finder でコピーしたときと同じファイルとしてクリップボードへ載せる。
ObjC.import('AppKit');
ObjC.import('stdlib');

// UniformTypeIdentifiers は BridgeSupport を持たず ObjC.import できないため、実行時にクラスを引く。
const UTType = $.NSClassFromString('UTType');
const fileManager = $.NSFileManager.defaultManager;

// git と同じく先頭 8000 バイトに NUL があればバイナリとみなし、巨大な動画を丸読みしない。
const BINARY_SNIFF_BYTES = 8000;

// JXA の console.log は stderr へ出るため、stdout を汚さずに結果を知らせられる。
function report(message) {
  console.log(`clip: ${message}`);
}

function fail(message) {
  report(message);
  $.exit(1);
}

function absolutePath(path) {
  const joined = path.startsWith('/') ? path : `${fileManager.currentDirectoryPath.js}/${path}`;
  return $(joined).stringByStandardizingPath.js;
}

// シンボリックリンク自体は型が public.symlink になるため、種類の判定はリンク先で行う。
function resolvedPath(path) {
  return $(path).stringByResolvingSymlinksInPath.js;
}

// 名前付きパイプ等を読むと書き手が来るまで止まるため、中身を見るのは通常ファイルだけにする。
function isRegularFile(path) {
  const attributes = fileManager.attributesOfItemAtPathError(path, null);
  return !attributes.isNil() && attributes.objectForKey('NSFileType').js === 'NSFileTypeRegular';
}

function contentType(path) {
  const type = Ref();
  // 定数 NSURLContentTypeKey も BridgeSupport に無いため、同じ値の文字列で渡す。
  $.NSURL.fileURLWithPath(path).getResourceValueForKeyError(type, 'NSURLContentTypeKey', null);
  return type[0];
}

function conformsTo(type, identifier) {
  return !type.isNil() && type.conformsToType(UTType.typeWithIdentifier(identifier));
}

function readUtf8Text(path) {
  const handle = $.NSFileHandle.fileHandleForReadingAtPath(path);
  const head = handle.readDataOfLength(BINARY_SNIFF_BYTES);
  handle.closeFile;
  const nul = $.NSData.alloc.initWithBase64EncodedStringOptions('AA==', 0);
  if (head.rangeOfDataOptionsRange(nul, 0, $.NSMakeRange(0, head.length)).length > 0) {
    return null;
  }
  const text = $.NSString.alloc.initWithDataEncoding($.NSData.dataWithContentsOfFile(path), $.NSUTF8StringEncoding);
  return text.isNil() ? null : text;
}

function writeItem(item) {
  const pasteboard = $.NSPasteboard.generalPasteboard;
  pasteboard.clearContents;
  if (!pasteboard.writeObjects($([item]))) {
    fail('クリップボードへの書き込みに失敗しました');
  }
}

function copyText(text) {
  const item = $.NSPasteboardItem.alloc.init;
  item.setStringForType(text, $.NSPasteboardTypeString);
  writeItem(item);
}

function copyImage(path) {
  const type = contentType(path);
  if (!conformsTo(type, 'public.image')) {
    return false;
  }
  const image = $.NSImage.alloc.initWithContentsOfFile(path);
  if (image.isNil()) {
    return false;
  }
  const tiff = image.TIFFRepresentation;
  const png = conformsTo(type, 'public.png')
    ? $.NSData.dataWithContentsOfFile(path)
    : $.NSBitmapImageRep.imageRepWithData(tiff).representationUsingTypeProperties($.NSBitmapImageFileTypePNG, $({}));
  const item = $.NSPasteboardItem.alloc.init;
  // GIF のアニメーションや JPEG の画質を読める受け手には元のバイト列を渡し、読めない受け手は PNG / TIFF を拾う。
  if (!conformsTo(type, 'public.png') && !conformsTo(type, 'public.tiff')) {
    item.setDataForType($.NSData.dataWithContentsOfFile(path), type.identifier);
  }
  item.setDataForType(png, $.NSPasteboardTypePNG);
  item.setDataForType(tiff, $.NSPasteboardTypeTIFF);
  writeItem(item);
  return true;
}

// 動画・PDF・zip・ディレクトリ等は貼り付け先が読めるデータ型が無いため、ファイル参照を載せて添付や複製を受け手に任せる。
function copyFileReference(path) {
  writeItem($.NSURL.fileURLWithPath(path));
}

function run(argv) {
  if (argv.length !== 1) {
    fail('使い方: clip <パス>');
  }
  const path = absolutePath(argv[0]);
  if (!fileManager.fileExistsAtPath(path)) {
    fail(`見つかりません: ${path}`);
  }

  const target = resolvedPath(path);
  if (isRegularFile(target)) {
    // .ts は macOS では MPEG-2 動画の型に解決されるため、型より先に中身でテキストを判定する。
    const text = readUtf8Text(target);
    if (text !== null) {
      copyText(text);
      report(`テキストをコピーしました: ${path}`);
      return;
    }
    if (copyImage(target)) {
      report(`画像をコピーしました: ${path}`);
      return;
    }
  }

  copyFileReference(path);
  report(`ファイルをコピーしました: ${path}`);
}
