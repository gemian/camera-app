#ifndef ADDDATESTAMP_H
#define ADDDATESTAMP_H

#include <QThread>
#include <exiv2/exiv2.hpp>

class AddDateStamp : public QThread
{
    static constexpr float MAXIMUM_TEXT_HEIGHT_PECENT_OF_IMAGE = 0.04f;
    static constexpr float MINIMUM_TEXT_HEIGHT_PECENT_OF_IMAGE = 0.02f;

public:
    AddDateStamp(QString inPath, QString dateFormat, QColor  stampColor, float   opacity, int alignment);
    void run();

protected:
    int rotationToAligment(int rotation);
    int getOrientation(QString pathToImage);
    void copyMetadata(QString srcPath, QString dstPath);
    
    QString path;
    QString dateFormat;
    QColor  stampColor;
    float   opacity;
    int    alignment;

};

#endif // ADDDATESTAMP_H
