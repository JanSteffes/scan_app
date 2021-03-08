class FileItem implements Comparable<FileItem> {
  String fileName;
  int selectIndex;

  FileItem(this.fileName);

  @override
  int compareTo(FileItem other) {
    return selectIndex.compareTo(other.selectIndex);
  }
}
