#include <metal_stdlib>
using namespace metal;
#include <SceneKit/scn_metal>

struct myLineNodeBuffer {
    float4x4 modelTransform;
    float4x4 modelViewTransform;
    float4x4 normalTransform;
    float4x4 modelViewProjectionTransform;
};


typedef struct {
    float3 position [[ attribute(SCNVertexSemanticPosition) ]];
    float3 a_color [[ attribute(SCNVertexSemanticColor) ]];
} LineVertexInput;

struct SimpleLineVertex
{
    float4 position [[position]];
    float3 color;
};

vertex SimpleLineVertex myLineVertex(LineVertexInput in [[ stage_in ]],
                             constant SCNSceneBuffer& scn_frame [[buffer(0)]],
                             constant myLineNodeBuffer& scn_node [[buffer(1)]])
{
    SimpleLineVertex vert;
    vert.position = scn_node.modelViewProjectionTransform * float4(in.position, 1.0);
    //in.a_color.x = 1.0;
    vert.color = in.a_color;
    return vert;
}

fragment float4 myLineFragment(SimpleLineVertex in [[stage_in]])
{
    return(float4(in.color,1));
}
