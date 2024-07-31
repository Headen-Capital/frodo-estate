// import { WalletButton } from "components/WalletButton";
import { Flex, Image, Typography } from "antd";
import React, { useEffect } from "react";
import { PageLayout } from "../components/page.layout";
import { useRouter } from "next/router";

const { Text, Title } = Typography;

type Props = {
  title?: string;
  description?: string;
};

const Home: React.FC<Props> = ({ title = "Frodo Estate", description }) => {
  const router = useRouter()

  useEffect(()=>{
    const res = setTimeout(()=>{
      router.push('/home')
    }, 2000)

    return ()=> clearTimeout(res)
  },[])
  return (
      <PageLayout layout="full-width" isCentered={true} type={'none'}>
      <Flex justify="center" align="center" vertical style={{height:"100vh"}}>
        <Image
          height={100}
          width={100}
          preview={false}
          src="https://marblism-dashboard-api--production-public.s3.us-west-1.amazonaws.com/VYaOvI-frodoestate-NC5f"
        />
      
        <Title level={3} style={{ margin: 2 }}>
          {title}
        </Title>
        {description && <Text type="secondary">{description}</Text>}
      </Flex>
    </PageLayout>
  );
};

export default Home;
