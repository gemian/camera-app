#include <QtCore/QFile>
#include <QImage>
#include <QPainter>
#include <QDate>
#include <QLocale>
#include <QDebug>


#include "adddatestamp.h"

AddDateStamp::AddDateStamp(QString inPath, QString dateFormat, QColor  stampColor, float   opacity, int alignment) {
    this->path = inPath;
    this->dateFormat = dateFormat;
    this->stampColor = stampColor;
    this->opacity = opacity;
    this->alignment = alignment;
}

void AddDateStamp::run() {
  try {

      QImage image = QImage(this->path);
      QDateTime now = QDateTime::currentDateTime();
      //Rotate image to match it`s orentation
      int orientation = this->getOrientation(this->path);
      QTransform trasform = QTransform();
      trasform.rotate(orientation);
      image = image.transformed(trasform);
      qDebug() << "orientation  : " <<  orientation;
      QString currentDate = QString(now.toString(this->dateFormat));
      int imageHeight = std::max(image.width(),image.height());
      int imageWidth = std::min(image.width(),image.height());
      int textPixelSize = std::min( (int) ( imageHeight * MAXIMUM_TEXT_HEIGHT_PECENT_OF_IMAGE),
                                        std::max( (imageWidth / 3) / currentDate.length() ,
                                    (int) ( imageHeight * MINIMUM_TEXT_HEIGHT_PECENT_OF_IMAGE) )  );

      QFont font = QFont("Helvetica");
      font.setPixelSize(textPixelSize);
      QPainter* painter = new QPainter(&image);
      painter->setFont(font);
      painter->setOpacity(this->opacity);
      painter->setPen(this->stampColor);
      QRect imageRect = QRect(textPixelSize,textPixelSize,image.width()-textPixelSize*2,image.height()-textPixelSize*2);
      //painter->setTransform(trasform);
      painter->drawText(imageRect, this->alignment, currentDate);
      
      //Rotate image back to it`s orginal orientation
      trasform.rotate(-orientation*2);
      image = image.transformed(trasform);
      
      //Save to a temporary location and preform a filename swap in order to keep the file fully rendered
      QString tmpPath = QString(path).replace(QRegExp("(\\.\\w+)$"),"_tmp\\1");
      QString backupFilePath = QString(path).replace(QRegExp("(\\.\\w+)$"),"_old\\1");
      
      image.save(tmpPath);
      this->copyMetadata(path, tmpPath);
      
      bool success = QFile::rename(path,backupFilePath);
      success &= QFile::rename(tmpPath, path);
      if(success) {
          QFile::remove(backupFilePath);
      } else { //try and move the backup file back to it original name
          QFile::rename(backupFilePath, path);
      }
  } catch (const std::exception& e) {
       qDebug() << "Failed when adding timestamp to image  : " <<  e.what();
      return ;
  }
}

int AddDateStamp::rotationToAligment(int rotation) {
    switch(rotation % 360) {
        case 0:
            return Qt::AlignTop | Qt::AlignLeft;
        case 90: 
            return Qt::AlignTop | Qt::AlignRight;
        case 180:
            return Qt::AlignBottom | Qt::AlignRight;
        case 270:
            return Qt::AlignBottom | Qt::AlignLeft;
    }
    return Qt::AlignTop | Qt::AlignLeft;
}

int AddDateStamp::getOrientation(QString pathToImage) {
     const std::string& srcExifPath = pathToImage.toStdString();
      Exiv2::Image::AutoPtr exifImageFile;
      exifImageFile = Exiv2::ImageFactory::open(srcExifPath);
      exifImageFile->readMetadata();
      Exiv2::ExifData &exifData = exifImageFile->exifData();
      long orientationFlags  = exifData["Exif.Image.Orientation"].toLong();
      
      return orientationFlags ? ((orientationFlags - 1) & 0x3)  * 90 : 0;
}

void AddDateStamp::copyMetadata(QString srcPath, QString dstPath) {
      const std::string& srcExifPath = srcPath.toStdString();
      Exiv2::Image::AutoPtr srcImageFile;
      srcImageFile = Exiv2::ImageFactory::open(srcExifPath);
      srcImageFile->readMetadata();

      const std::string& dstExifPath = dstPath.toStdString();
      Exiv2::Image::AutoPtr dstImageFile;
      dstImageFile = Exiv2::ImageFactory::open(dstExifPath);
      
      dstImageFile->setMetadata(*srcImageFile);
      dstImageFile->setExifData(srcImageFile->exifData());
      dstImageFile->writeMetadata();
}
