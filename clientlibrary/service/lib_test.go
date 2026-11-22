package service

import (
	"fmt"
	"testing"

	"github.com/gogo/protobuf/proto"

	"github.com/anyproto/anytype-heart/core/api"
	"github.com/anyproto/anytype-heart/pb"
)

func TestUnpack(t *testing.T) {
	b, _ := proto.Marshal(&pb.RpcWalletRecoverResponse{})

	var msg pb.RpcWalletRecoverResponse
	err := proto.Unmarshal(b, &msg)
	if err != nil {
		fmt.Println(err.Error())
	}
}

// The JSON API resolves its middleware from a package-level value that the
// embedder sets. cmd/grpcserver sets it; the mobile library must too, or
// every authenticated JSON API request panics on a nil middleware (HTTP 500).
func TestMobileLibrarySetsApiMiddlewareParams(t *testing.T) {
	if !api.MiddlewareParamsSet() {
		t.Fatal("clientlibrary/service init did not call api.SetMiddlewareParams; authenticated JSON API requests will fail with 500")
	}
}
