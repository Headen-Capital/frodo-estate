'use client'

import { useEffect, useState } from 'react'
import { Button, Card, Col, Row, Typography } from 'antd'
import { WalletOutlined } from '@ant-design/icons'
const { Title, Text } = Typography
import dayjs from 'dayjs'
import { useSnackbar } from 'notistack'
import { useRouter, useParams } from 'next/navigation'
import { PageLayout } from '../components/page.layout'

export default function HomePage() {
  const router = useRouter()
  const { enqueueSnackbar } = useSnackbar()
  const [products, setProducts] = useState<any[]>([])
  const [isLoading, setIsLoading] = useState<boolean>(true)

  useEffect(() => {
    const fetchProducts = async () => {
      setIsLoading(false)
    }

    const demoProducts = [
      {
        id: '1',
        name: 'Demo Product 1',
        price: 10,
        description: 'This is a demo product 1',
        imageUrl: 'https://images.pexels.com/photos/259588/pexels-photo-259588.jpeg?auto=compress&cs=tinysrgb&w=800&h=400'
      },
      {
        id: '2',
        name: 'Demo Product 2',
        price: 20,
        description: 'This is a demo product 2',
        imageUrl: 'https://images.pexels.com/photos/1481105/pexels-photo-1481105.jpeg?auto=compress&cs=tinysrgb&w=800&h=400'
      },
      {
        id: '3',
        name: 'Demo Product 3',
        price: 30,
        description: 'This is a demo product 3',
        imageUrl: 'https://images.pexels.com/photos/210617/pexels-photo-210617.jpeg?auto=compress&cs=tinysrgb&w=800&h=400'
      },
      {
        id: '4',
        name: 'Demo Product 4',
        price: 40,
        description: 'This is a demo product 4',
        imageUrl: 'https://images.pexels.com/photos/1396132/pexels-photo-1396132.jpeg?auto=compress&cs=tinysrgb&w=800'
      },
      {
        id: '5',
        name: 'Demo Product 5',
        price: 50,
        description: 'This is a demo product 5',
        imageUrl: 'https://images.pexels.com/photos/1732414/pexels-photo-1732414.jpeg?auto=compress&cs=tinysrgb&w=800&h=400'
      },
      {
        id: '6',
        name: 'Demo Product 6',
        price: 60,
        description: 'This is a demo product 6',
        imageUrl: 'https://images.pexels.com/photos/323780/pexels-photo-323780.jpeg?auto=compress&cs=tinysrgb&w=800&h=400'
      },
      {
        id: '7',
        name: 'Demo Product 7',
        price: 70,
        description: 'This is a demo product 7',
        imageUrl: 'https://images.pexels.com/photos/164522/pexels-photo-164522.jpeg?auto=compress&cs=tinysrgb&w=800&h=400'
      },
      {
        id: '8',
        name: 'Demo Product 8',
        price: 80,
        description: 'This is a demo product 8',
        imageUrl: 'https://images.pexels.com/photos/87223/pexels-photo-87223.jpeg?auto=compress&cs=tinysrgb&w=800&h=400'
      },
      {
        id: '9',
        name: 'Demo Product 9',
        price: 90,
        description: 'This is a demo product 9',
        imageUrl: 'https://images.pexels.com/photos/106399/pexels-photo-106399.jpeg?auto=compress&cs=tinysrgb&w=800&h=400'
      },
      {
        id: '10',
        name: 'Demo Product 10',
        price: 100,
        description: 'This is a demo product 10',
        imageUrl: 'https://images.pexels.com/photos/3288100/pexels-photo-3288100.png?auto=compress&cs=tinysrgb&w=800&h=400'
      }
    ]

    setProducts(demoProducts)
    fetchProducts()
  }, [])

  

  return (
    <PageLayout layout="full-width">
      <Title level={2} style={{ textAlign: 'center', marginTop: '20px' }}>
        Available Properties
      </Title>
      {/* <Text
        style={{ textAlign: 'center', display: 'block', marginBottom: '20px' }}
      >
        Connect your wallet to buy products with enough USDC in your wallet.
      </Text> */}
      <Row gutter={[16, 16]} justify="center">
        {isLoading ? (
          <Text>Loading properties...</Text>
        ) : (
          products?.map(product => (
            <Col key={product.id} xs={24} sm={12} md={8} lg={6}>
              <Card
                title={product.name}
                bordered={false}
                cover={<img style={{width: "300px", height:"200px"}} alt={product.name} src={product.imageUrl} />}
              >
                <Text>{product.description}</Text>
                <Text style={{ display: 'block', marginTop: '10px' }}>
                  Price: ${product.price}
                </Text>
                <Text style={{ display: 'block', marginTop: '10px' }}>
                  Available Lots: 200
                </Text>
                
                <Button
                  type="primary"
                  icon={<WalletOutlined />}
                  style={{ marginTop: '10px' }}
                  onClick={() => router.push(`/properties/${product.id}`)}
                >
                  View Details
                </Button>
                
              </Card>
            </Col>
          ))
        )}
      </Row>
    </PageLayout>
  )
}
