# 后端测试备注规范

> **Phase 4 辅助** · [phase4.md](../phases/phase4.md) · [04-test-case.md](04-test-case.md)

## 文件级备注

```go
// Package <包名> <测试用例名称>
//
// ==================== 测试说明 ====================
// <测试内容说明>
//
// 测试覆盖内容：
// 1. 覆盖内容 1
// 2. 覆盖内容 2
// 3. 覆盖内容 3
//
// 运行测试：<运行指令>
// ==================================================
```

## 方法级备注

```go
// <方法名> 中文方法名
//
// 【功能点】<具体功能点>
// 【测试流程】
// 1. 测试流程 1
// 2. 测试流程 2
// 3. 测试流程 3
```

## 表驱动测试模板

```go
func TestXxxService_Method(t *testing.T) {
    tests := []struct {
        name    string
        input   *model.Input
        mock    func(*mocks.MockRepo)
        want    *model.Output
        wantErr error
    }{
        {
            name:  "正常场景",
            input: &model.Input{Name: "test"},
            mock: func(m *mocks.MockRepo) {
                m.EXPECT().Method(gomock.Any(), gomock.Any()).Return(nil)
            },
            want: &model.Output{Name: "test"},
        },
        {
            name:  "异常场景",
            input: &model.Input{Name: ""},
            mock:  func(m *mocks.MockRepo) {},
            wantErr: service.ErrInvalidInput,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            ctrl := gomock.NewController(t)
            defer ctrl.Finish()

            mockRepo := mocks.NewMockRepo(ctrl)
            tt.mock(mockRepo)

            svc := service.NewXxxService(mockRepo)
            got, err := svc.Method(context.Background(), tt.input)

            if tt.wantErr != nil {
                assert.ErrorIs(t, err, tt.wantErr)
                return
            }
            assert.NoError(t, err)
            assert.Equal(t, tt.want.Name, got.Name)
        })
    }
}
```
