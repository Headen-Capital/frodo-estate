'use client'

import { useEffect, useState } from 'react'
import { Button, Card, Col, Row, Typography, Spin } from 'antd'
import { WalletOutlined, ShoppingCartOutlined } from '@ant-design/icons'
const { Title, Text, Paragraph } = Typography
import dayjs from 'dayjs'
import { useSnackbar } from 'notistack'
import { useRouter, useParams } from 'next/navigation'
import { PageLayout } from '../../components/page.layout'

export default function PropertyDetailsPage() {
  const router = useRouter()
  const params = useParams<any>()
  
  const { enqueueSnackbar } = useSnackbar()
  const [property, setProperty] = useState<any | null>(null)
  const [loading, setLoading] = useState<boolean>(true)

  useEffect(() => {
    const fetchPropertyDetails = async () => {
      try {
        const propertyDetails:any[] = []
        const property = propertyDetails.find(
          (p: any) => p.id === params?.propertyId,
        )
        setProperty( {
          id: '10',
          name: 'Demo Product 10',
          price: 100,
          description: 'This is a demo product 10',
          imageUrl: 'https://images.pexels.com/photos/681368/pexels-photo-681368.jpeg?auto=compress&cs=tinysrgb&w=800'
        })
      } catch (error) {
        enqueueSnackbar('Failed to fetch property details', {
          variant: 'error',
        })
      } finally {
        setLoading(false)
      }
    }

    fetchPropertyDetails()
  }, [params?.propertyId])

  const handleBuy = async () => {
      // enqueueSnackbar('You need to be logged in to make a purchase', {
      //   variant: 'error',
      // })
      // return
    

    try {
      const isConnected = await connectToWeb3Wallet()
      if (!isConnected) {
        enqueueSnackbar('Failed to connect to wallet', { variant: 'error' })
        return
      }

      const hasEnoughBalance = await checkUSDCBalance()
      if (!hasEnoughBalance) {
        enqueueSnackbar('Insufficient USDC balance', { variant: 'error' })
        return
      }

      
      enqueueSnackbar('Purchase successful', { variant: 'success' })
      router.push('/vault')
    } catch (error) {
      enqueueSnackbar('Purchase failed', { variant: 'error' })
    }
  }

  if (loading) {
    return (
      <PageLayout layout="full-width">
        <Spin size="large" />
      </PageLayout>
    )
  }

  if (!property) {
    return (
      <PageLayout layout="full-width">
        <Title level={2}>Property Not Found</Title>
        <Text>The property you are looking for does not exist.</Text>
      </PageLayout>
    )
  }

  return (
    <PageLayout layout="full-width">
      <Row justify="center" gutter={[16, 16]}>
        <Col xs={24} sm={24} md={16} lg={12}>
          <Card cover={<img alt={property.name} src={property.imageUrl} />}>
            <Title level={2}>{property.name}</Title>
            <Paragraph>{property.description}</Paragraph>
            <Text strong>Location: </Text>
            <Text>{property.location?.address}</Text>
            <br />
            <Text strong>Owner: </Text>
            <Text>{property.owner?.name}</Text>
            <br />
            <Text strong>Date Listed: </Text>
            <Text>{dayjs(property.dateListed).format('MMMM D, YYYY')}</Text>
            <br />
            <Button
            style={{marginTop:"24px"}}
              type="primary"
              icon={<ShoppingCartOutlined />}
              onClick={handleBuy}
            >
              Buy
            </Button>
          </Card>
        </Col>
      </Row>
    </PageLayout>
  )
}

// Mock functions for web3 wallet connection and balance check
const connectToWeb3Wallet = async (): Promise<boolean> => {
  return true
}

const checkUSDCBalance = async (): Promise<boolean> => {
  return true
}
