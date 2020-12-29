#ifndef ADDDATESTAMP_H
#define ADDDATESTAMP_H

#include <map>

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
    long getOrientation(QString pathToImage);
    int getRotationByOrientation(long orientationFlags);
    bool isOrientationMirrored(long orientationFlags);
    void copyMetadata(QString srcPath, QString dstPath);
    
    QString path;
    QString dateFormat;
    QColor  stampColor;
    float   opacity;
    int     alignment;
    
    std::map<long, int> orientationMapping = {
        {1,0},
        {2,0},
        {3,180},
        {4,180},
        {5,90},
        {6,90},
        {7,270},
        {8,270},
    };
    
    std::map<long, bool> mirrorMapping = {
        {1,false},
        {2,true},
        {3,false},
        {4,true},
        {5,true},
        {6,false},
        {7,true},
        {8,false},
    };
};

#endif // ADDDATESTAMP_H
