import { ConnectButton } from '@rainbow-me/rainbowkit'
import { Divider, Flex, Menu } from 'antd'
import Sider from 'antd/es/layout/Sider'
import { usePathname } from 'next/navigation'
import { ReactNode } from 'react'

interface Props {
  logo: ReactNode
  items: { key: string; label: string; onClick: () => void }[]
  itemsUser: { key: string; label: string; onClick: () => void }[]
}

export const Leftbar: React.FC<Props> = ({ logo, items, itemsUser }) => {
  const pathname = usePathname()

  return (
    <> 
      <Sider width={500} trigger={null} style={{ height: '100%' }}>
        <Flex style={{alignItems: 'center', flexWrap:'wrap'}}>{logo} <Flex style={{width:'70%', justifyContent:'space-around'}}><ConnectButton label="Connect Wallet" /> </Flex></Flex>

        <Menu
          mode="inline"
          items={items}
          selectedKeys={[pathname]}
          style={{ width: '100%', marginTop:"24px" }}
        />
        {itemsUser?.length > 0 && (
          <>
            <Divider style={{ marginTop: 5, marginBottom: 5 }} />
            <Menu
              mode="inline"
              items={itemsUser}
              selectedKeys={[pathname]}
              style={{ width: '100%' }}
            />
          </>
        )}
      </Sider>
    </>
  )
}
