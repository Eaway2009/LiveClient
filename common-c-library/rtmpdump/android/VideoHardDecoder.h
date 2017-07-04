//
//  VideoHardDecoder.h
//  RtmpClient
//
//  Created by  Samson on 05/06/2017.
//  Copyright © 2017 net.qdating. All rights reserved.
//  视频硬解码实现类

#ifndef VideoHardDecoder_h
#define VideoHardDecoder_h

#include <rtmpdump/android/JniGobalFunc.h>

#include <rtmpdump/IDecoder.h>
#include <rtmpdump/VideoFrame.h>

#include <common/KThread.h>

namespace coollive {
class DecodeVideoHardRunnable;
class RtmpPlayer;
class VideoHardDecoder : public VideoDecoder {
public:
    VideoHardDecoder();
    VideoHardDecoder(jobject jniDecoder);
    virtual ~VideoHardDecoder();

public:
    bool Create(VideoDecoderCallback* callback);
    void Reset();
    void Pause();
    void ResetStream();
    void DecodeVideoKeyFrame(const char* sps, int sps_size, const char* pps, int pps_size, int nalUnitHeaderLength);
    void DecodeVideoFrame(const char* data, int size, u_int32_t timestamp, VideoFrameType video_type);
    void ReleaseVideoFrame(void* frame);
    void StartDropFrame();
    
protected:
    void Init();
    void Stop();
    void ReleaseBuffer(VideoFrame* videoFrame);
    void HandleVideoFrame(JNIEnv* env, jclass jniDecoderCls, jobject jVideoFrame);
    void TransYUV_NV21_RGB_8888(char* inputYUV, int width, int height, char* outputRGB);

private:
    // 解码线程实现体
    friend class DecodeVideoHardRunnable;
    void DecodeVideoHandle();

private:
    VideoDecoderCallback* mpCallback;
    jobject mJniDecoder;

    // 解码器变量
    char* mpSps;
    int mSpSize;
    char* mpPps;
    int mPpsSize;
    int mNalUnitHeaderLength;

    jbyteArray spsByteArray;
    jbyteArray ppsByteArray;
    jbyteArray dataByteArray;

    // 解码线程
    KThread mDecodeVideoThread;
    DecodeVideoHardRunnable* mpDecodeVideoRunnable;
    // 状态锁
    KMutex mRuningMutex;
    bool mbRunning;

    // 空闲Buffer
    EncodeDecodeBufferList mFreeBufferList;
};
}

#endif /* VideoHardDecoder_h */