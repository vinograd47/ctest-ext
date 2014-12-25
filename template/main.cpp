#include "gtest.h"

static int func_1(int a, int b)
{
    return a + b;
}

static int func_2(int a, int b)
{
    return a - b;
}

static int func_3(int a, int b)
{
    return a + b;
}

TEST(Func, Test1)
{
    ASSERT_EQ(4, func_1(2, 2));
}

TEST(Func, Test2)
{
    ASSERT_EQ(2, func_2(4, 2));
}

TEST(Func, Test3)
{
    ASSERT_EQ(4, func_3(2, 2));
}

int main(int argc, char* argv[])
{
    testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
